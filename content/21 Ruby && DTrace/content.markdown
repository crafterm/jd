Performance, memory and runtime analysis of software has always been a tricky subject, often requiring special debug versions of code or application specific parameters to determine what's going on. Additionally, developer debugging information can often clutter source code making it harder to see the intent and design of source.

[D-Trace](http://www.sun.com/bigadmin/content/dtrace/) offers an interesting solution to this problem, by dynamically instrumenting your application at runtime to enable probes to report various pieces of information as to how your application is running. DTrace is a part of [Solaris](http://sun.com/solaris/), but is now also available under [Mac OS X Leopard](http://www.apple.com/macosx/). A typical installation of DTrace can offer 20,000 different types of probes (or more depending on what applications are running), from kernel level information, all the way to application specific data.

Applications, such as the Ruby interpreter can also define their own domain specific probes, last year [Joyent](https://dev.joyent.com/projects/ruby-dtrace/wiki/Ruby+DTrace) added support for D-Trace probes to MRI (Matz-Ruby), allowing developers to analyze runtime behaviour of their Ruby based applications. Starting with this particular [commit](http://github.com/evanphx/rubinius/commit/46513843cedfe47bd5710aa3756230aa15a1570a), I've also started adding compatible D-Trace probes to [Rubinius](http://rubini.us/).

## What can you do with DTrace?

The list of uses for DTrace are endless, as it provides the means to gain answers to many questions about how your application is behaving. Some practical questions DTrace can answer include:

* Tracing execution flow through your application as it steps through each method/class
* Determining runtime performance analysis, working out what methods are the most expensive (excellent for 80/20 performance analysis)
* Heap analysis, determining what objects are consuming the most memory
* Garbage collection impact, determining how often the garbage collector is running an impacting your applications performance
* and much more...

## Getting started with DTrace and Ruby

To get started with Ruby and DTrace, you'll need a compatible operating system, eg. Mac OS X Leopard, and you'll need to get the Ruby source to build MRI with Joyent's DTrace [patches](http://svn.joyent.com/opensource/dtrace/ruby/patches/). Luckily, if you're using Mac OS X Leopard, Apple has already appropriately patched their bundled version of Ruby to include DTrace patches for you, and no extra compilation is necessary. DTrace itself is also included by default under all Mac OS X Leopard operating system installs.

## DTrace primer

There is a wealth of information available on the internet that I'd certainly recommend taking a look at to learn using DTrace in depth (in particular Sun's DTrace admin [guides](http://www.sun.com/bigadmin/content/dtrace/)). Essentially to interact with DTrace, you write a script in a language called 'D', which defines what probes you're interested in, and what to do with the data when the probe fires. This script is then read and bytecode compiled by DTrace's command line and user land libraries, and then passed to the DTrace virtual machine running inside of the kernel to be interpreted. Probes are enabled, and appropriately fired, with data being collected according to your scripts for analysis.

### Anatomy of a DTrace script

    provider : module : function : name
    / predicate /
    {
      action
    }

Above is generic breakdown of a DTrace script (parts of it bearing similarity to an awk script). Most parts of the script are optional as you'll see further, such as the module or function name, or even the action.

Probes are grouped by _providers_, of which there are many (io, pid, objc, profile, to name a few). _module_ and _function_'s meaning are somewhat dependant on the provider being used. The _name_ parameter identifies the actual name of the probe that is to be fired.

The predicate is identifies a clause that must evaluate to true for the probe to fire and allows for conditional firing of probes.

The action contains arbitrary instructions to be performed when the probe fires.

To probe your application you also need root privileges on the machine you'll be running DTrace on, this is due to kernel level interaction of DTrace. Usually you'll run DTrace and pass it the name of a D script (or include the script on the command line if it's brief), either with a command to run, or a process ID of an application that's already running that should be attached to. For example:

    $> sudo dtrace -s profile.d -c 'ruby -e "puts 'gday australia!'"'

or:

    $> ps aux|grep ruby
    crafterm 29877   0.0  0.0   590472    188 s001  R+    5:04pm   0:00.00 grep ruby
    crafterm 29875   0.0  1.2   622564  25016 s001  S     5:04pm   0:00.85 ruby
    $> sudo dtrace -s profile.d 29875

## Ruby Provider Probes

To see how many probes and what Ruby probes are available, we can ask DTrace to print their specifics to the console, eg:

    $> sudo dtrace -l | wc -l
    31569

indicating I currently have 31569 probes available to query, this number will change depending on what applications are running at the time of running the dtrace command. Ruby specific probes can be found by:

    $> sudo dtrace -l | grep ruby
    21427  ruby53816   libruby.1.dylib                          rb_call0 function-entry
    21428  ruby53816   libruby.1.dylib                          rb_call0 function-return
    21429  ruby53816   libruby.1.dylib                   garbage_collect gc-begin
    21430  ruby53816   libruby.1.dylib                   garbage_collect gc-end
    21431  ruby53816   libruby.1.dylib                           rb_eval line
    21432  ruby53816   libruby.1.dylib                      rb_obj_alloc object-create-done
    21433  ruby53816   libruby.1.dylib                      rb_obj_alloc object-create-start
    21434  ruby53816   libruby.1.dylib                   garbage_collect object-free
    21435  ruby53816   libruby.1.dylib                        rb_longjmp raise
    21436  ruby53816   libruby.1.dylib                           rb_eval rescue
    21437  ruby53816   libruby.1.dylib                 ruby_dtrace_probe ruby-probe

As you can see from the list in the last column of the output, probes are available between method invocations, runs of the garbage collector, creation and destruction of objects and exceptions. The last probe actually allows the application writer to fire an arbitrary ruby probe containing application specific data from ruby code. A full list of probes and arguments supplied to them is available at Joyent's Ruby provider wiki [page](https://dev.joyent.com/projects/ruby-dtrace/wiki/Ruby+DTrace+probes+and+arguments).

## Example 1: Tracing execution flow through your application

Lets start by tracing the execution flow through a small Ruby program.

### Simple Ruby Program

    class World
      def say(message)
        puts message
      end
    end

    world = World.new
    world.say('hello')

This small Ruby program creates an instance of the World class, sends it the _say_ message with _hello_ as a String parameter which is printed to the console.

### Execution Flow D script

    ruby$target:::function-entry
    {
       printf("%s:%s\n", copyinstr(arg0), copyinstr(arg1));
    }

    ruby$target:::function-return
    {
       printf("%s:%s\n", copyinstr(arg0), copyinstr(arg1));
    }

This particular script enables the function-entry probe on the Ruby provider, and prints the first and second arguments passed to the probe in a C-style printf command. The first and second arguments passed are provider specific, but in the Ruby provider's case for these probes they are always the class/module and method names being executed. The $target variable enables the probe on the PID of the command specified via the -c parameter to DTrace itself.

### Results

    $> sudo dtrace -q -F -s execution-flow.d -c "ruby hello.rb"
    CPU FUNCTION
    1  -> rb_call0                              Class:inherited
    1  <- rb_call0                              Class:inherited
    1  -> rb_call0                              Module:method_added
    1  <- rb_call0                              Module:method_added
    1  -> rb_call0                              Class:new
    1    -> rb_call0                            Object:initialize
    1    <- rb_call0                            Object:initialize
    1  <- rb_call0                              Class:new
    1  -> rb_call0                              World:say
    1    -> rb_call0                            Object:puts
    1      -> rb_call0                          IO:write
    1      <- rb_call0                          IO:write
    1      -> rb_call0                          IO:write
    1      <- rb_call0                          IO:write
    1    <- rb_call0                            Object:puts
    1  <- rb_call0                              World:say

Taking a look at the results we can almost visually 'see' how the script was parsed and executed. First Class was 'inherited', this is part of the creation of our 'World' class, then we defined World#say (invoking the Module:method\_added method) to contain some operations. We then created a new instance of our class (Class:new and Object:initialize to create and construct our object), and then invoked World#say which we can see calls Object:puts and IO:write.

(In this particular case, the program is small and the instructions simple, however just add _"require 'rubygems'"_ to the top of the source and re-run the DTrace script again and you'll quickly be overwhelmed with too much information - writing effective DTrace scripts is an art, but it's well worth learning to ensure you get the answers you're looking for)

## Example 2: Individual Method Performance

Lets use DTrace to take another look at our application from a different perspective and see what methods are most expensive. To do this we'll use the function entry and return probes to capture a time stamp interval for each method call. We'll also use an aggregate DTrace variable to store a running average of how long each method takes so that multiple method calls are recorded together and averaged across the count of method invocations, and we'll print the results according to most expensive method execution time.

### Method Performance DTrace script

    ruby$target:::function-entry
    {
      self->start = timestamp;
    }

    ruby$target:::function-return
    /self->start/
    {
      @[copyinstr(arg0), copyinstr(arg1)] = avg(timestamp - self->start);
      self->start = 0;
    }

This script introduces a few more DTrace constructs, associative arrays and aggregate functions.

We enable two probes, function entry and function return on our Ruby program. When any method is entered, we capture a timestamp and store it in the 'start' variable. When any method is exited, we gather another timestamp, subtract it from the entry, and pass it to the __avg__ DTrace aggregate function to be averaged. The average execution time is then stored in an associative array, indexed by the module/class and method name (arg0 and arg1 respectively). Finally, we reset 'start' to zero once its no longer required. A predicate is also set on the function return probe to only fire if we have a start timestamp value, which prevents us from seeing any errors if we attach our DTrace script to an application that is already running (since after attaching, a return probe could fire for which we have no start timestamp).

### Results

    $> sudo dtrace -s timestamps.d -c "ruby hello.rb"
    Object                   initialize                     9185
    Module                   method_added                   10021
    Class                    inherited                      25323
    IO                       write                          98956

DTrace automatically prints data collected unless you supply a custom output format (eg. by using the C-style printf DTrace function as in the method flow example above) which in this case is the associative array, indexed by class/module and method name. From these results we can see that IO#write was the slowest of the methods called, taking an average of 98956 nanaseconds to run, most likely due to its interation with the rest of the system and IO nature.

## Example 3: Quantized Method Performance

Average values can often be affected by a few large values during program startup, so lets take a closer look and see what values consititue the calculation the averages above. To do this we'll use the DTrace __quantize__ aggregate function, which will provide us with a distribution breakdown of each individual component within the average. We'll also specifically target the IO#write method, and update our Ruby program to print 'hello' 10 times to collect some more data over a period of invocations.

    ruby$target:::function-entry
    /copyinstr(arg0) == "IO" && copyinstr(arg1) == "write"/
    {
      self->start = timestamp;
    }

    ruby$target:::function-return
    /copyinstr(arg0) == "IO" && copyinstr(arg1) == "write" && self->start/
    {
      @[copyinstr(arg0), copyinstr(arg1)] = quantize(timestamp - self->start);
      self->start = 0;
    }

### Results

    $> sudo dtrace -s timestamps-q.d -c "ruby hello.rb"

      IO                                                  write
               value  ------------- Distribution ------------- count
                4096 |                                         0
                8192 |@@@@@@@@@@@@@@@@@@@@                     10
               16384 |@@@@@@@@@@@@@@@@                         8
               32768 |@@                                       1
               65536 |                                         0
              131072 |@@                                       1
              262144 |                                         0

Here we see the distribution of how long each invocation of IO#write took. There was one invocation that particuarly long, over 131k nanoseconds, with most landing between 8k and 16k nanoseconds. From here we could step further into the runtime and determine which particular IO#write call was slower than the others by inspecting the user stack inside the virtual machine, and/or by enabling probes in lower level providers.

## Example 4: Memory allocation

To profile memory allocation we need to enable the _object-create-start_, _object-create-done_, and _object-free_ probes. Creation of objects is separated into two probes to allow you to determine exactly how long it takes to construct an object.

First, lets create a simple balance script to check that objects are being allocated and deallocated correctly within the Ruby runtime. The script we'll use will create an associative array and index a counter by object type. Each time an object is created we'll increment the counter, conversely each time an object is freed we'll decrement the counter.

    ruby$target:::object-create-done { @[copyinstr(arg0)] = sum(1); }
    ruby$target:::object-free        { @[copyinstr(arg0)] = sum(-1); }

### Results

    $> sudo dtrace -s object-balance.d -c "ruby hello.rb"

      NoMemoryError                                                     1
      SystemStackError                                                  1
      ThreadGroup                                                       1
      World                                                             1
      fatal                                                             1
      Object                                                            3

Glancing over the results we can see that Ruby is creating an instance of several error classes and a thread group during the run of our application (perhaps during startup), we can also see a single instance of our _World_ class, and three other Objects that have also been allocated. Our particular hello.rb script is quite small, and probably finishes executing before the garbage collector has had a change to reclaim any unused objects. If you run this script over a large application though, you'll see a line for each Object in the application, and essentially a reference count of how many have been created and freed. In an ideal application, after garbarge collector has finished, all objects (except those required to keep the application running) types will be listed with the value '0' alongside it indicating a corresponding deallocation for each allocation.

## Example 5: Inspecting memory allocation points

The object-create-start/done probes also provide the source file and line number of where the allocation was made in Ruby script which we can use. For example if our World class came from another developer's library and we wanted to find out where it was allocated we could use the following script:

    ruby$target:::object-create-start
    /copyinstr(arg0) == "World"/
    {
      printf("%s was allocated in file %s, line number %d\n", copyinstr(arg0), copyinstr(arg1), arg2);
    }

### Results

    $> sudo dtrace -s object-balance.d -c "ruby hello.rb"

      World was allocated in file hello.rb, line number 7

which matches our source file.

## Example 6: Inspecting stack traces

We also saw above that several other 'Object's are created within the C portion of the Ruby interpreter upon startup. We can also inspect where these objects were created by saving the user C stack inside the virtual machine at the point of allocation.

    ruby$target:::object-create-start
    /copyinstr(arg0) == "Object"/
    {
      @[ustack(4)] = count();
    }

This particular script uses the DTrace _ustack_ function to access the actual runtime stack of the Ruby interpreter in userland at the point in time when the probe fired. We then use the stack as an index into an associative array and store the number of times an Object type was created at the same point in the interpreter. This example really shows how flexible associative arrays can be in DTrace, by using a full strack trace as an index.

### Results

    $> sudo dtrace -s object-user-stack.d -c "ruby hello.rb"

              libruby.1.dylib`rb_obj_alloc+0x90
              libruby.1.dylib`Init_Object+0x130b
              libruby.1.dylib`rb_call_inits+0x15
              libruby.1.dylib`ruby_init+0x14f
                1

              libruby.1.dylib`rb_obj_alloc+0x90
              libruby.1.dylib`Init_IO+0x1059
              libruby.1.dylib`rb_call_inits+0x6a
              libruby.1.dylib`ruby_init+0x14f
                1

              libruby.1.dylib`rb_obj_alloc+0x90
              libruby.1.dylib`Init_Hash+0x903
              libruby.1.dylib`rb_call_inits+0x51
              libruby.1.dylib`ruby_init+0x14f
                1

Here we can see three separate stack traces indicating a Hash, IO and Object being created as part of the ruby_init method inside the Ruby interpreter.

## Summary

DTrace is a very powerful framework, allowing you to really hypothesise and ask arbitrary questions about the behaviour of your system and applications. Often, the answer to one question will lead to another, and this is very much in the sprit of DTrace. The ability to script questions and format results allows you to slice behavioural data from any perspective and depth from your application, all the way to the operating system kernel.

DTrace scripts are the key to reducing complexity and understanding the true behaviour of your application at runtime, and I certainly recommend learning as much about the D script format and language as you can. Fine tuning your script to return the exact data you're after can be an art, but its well worth learning so that you can specify exactly what data you are after, and not be cluttered with too much information obscuring the information you are searching for.

Collections of commonly used DTrace scripts are available as part of the [DTraceToolkit](http://opensolaris.org/os/community/dtrace/dtracetoolkit/), in particular several very useful and high quality Ruby DTrace scripts. I also recommend taking a look at them to see how probes can be used in combination with each other, also in multi-threaded environments.

In future articles I'll step further into using DTrace via [Instruments](http://www.apple.com/macosx/developertools/instruments.html), and also look at instrumenting your Rails or Merb application to collect runtime data about the performance of your web applications.

