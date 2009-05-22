In a [previous](http://redartisan.com/2007/10/5/rubinius-getting-started) article we examined the process of checking out [Rubinius](http://rubini.us/), building it from source and discussed its directory structure. In this article, we'll take it one step further and examine the process of implementing an example method that can be contributed back to the project as a patch for inclusion in the official Rubinius source base.

If you haven't checked out or built Rubinius please see my [previous](http://redartisan.com/2007/10/5/rubinius-getting-started) post which details the preliminary steps required before we can start implementing.

The feature we'll implement is the _File.link_ method, the implementation is quite simple and only a few lines of code but it will take us through the process of adding a method to an existing class with an existing spec, and will also take us into the system call layer where we'll interact with the underlying operating system to perform a symlink.

In this case it's not required however generally it's a good idea to run the _rake dev:setup_ rake task before implementation to ensure that we have pristine copies of our runtime archives available. We do this because the compiler itself requires that the runtime archives work, and if we introduce a defect it's possible to enter the situation where we cannot compile a fix.

_dev:setup_ essentially makes a backup of the runtime archives that will always be used for compilation. In our particular case the compiler doesn't create any symlinks so this step is optional but it's a good idea if you're working on existing code or low level methods such as File.stat, Hash, Array, etc to do so.

Normally when using git we would create a feature branch, implement our specs and changes on that branch, commit it locally and then rebase the source code off the master branch before pushing it to the main repository (this is how Rubinius committers integrate their work into the main line development). In this article we'll omit these stages as they're well [documented](http://rubinius.lighthouseapp.com/projects/5089/using-git) on the Rubinius project pages, and here we want to focus on the changes to be made to Rubinius itself.

## Specification

Back to our new feature - a spec already exists for _File.link_ and it's in the spec/core/file/link_spec.rb file:

<filter:jscode lang="ruby">
require File.dirname(__FILE__) + '/../../spec_helper'

describe "File.link" do
  before do 
    @file = "test.txt"
    @link = "test.lnk"     
    File.delete(@link) if File.exists?(@link)
    File.delete(@file) if File.exists?(@file)
    File.open(@file, "w+")
  end

  platform :not, :mswin do
    it "link a file with another" do
      File.link(@file, @link).should == 0
      File.exists?(@link).should == true
      File.identical?(@file, @link).should == true
    end

    it "raise an exception if the target already exists" do
      File.link(@file, @link)
      should_raise(Errno::EEXIST) { File.link(@file, @link) }
    end

    it "raise an exception if the arguments are of the wrong type or are of the incorrect number" do
      should_raise(ArgumentError) { File.link }
      should_raise(ArgumentError) { File.link(@file) }
    end
  end

  after do
    File.delete(@link)
    File.delete(@file)
  end
end
</filter:jscode>

The core specification suite is laid out in the spec/core directory using the convention of a having a spec file per method on each class containing all behaviour for that corresponding method. Platform and bootstrap specs are in the spec/platform and spec/bootstrap directories respectively.

Examining the specification above, there's three tests that are run on all non-mswin platforms (ie. those supporting the creation of symlinks). The tests ensure that when called, File.link creates a symlink between the source and target, or raises an exception either if the target already exists or if it's given incorrect arguments.

This identifies what we need to implement.

Let's run the spec to see what's failing:

    $> bin/mspec -f s spec/core/file/link_spec.rb
    
    File.link
    - link a file with another  (ERROR - 1)
    - raise an exception if the target already exists (ERROR - 2)
    - raise an exception if the arguments are of the wrong type or are of the incorrect number (ERROR - 3)


    1)
    File.link link a file with another  FAILED
    No method 'link' on an instance of Class.: 
        Object(Class)#link (method_missing) at kernel/core/object.rb:98
                            main.__script__ at spec/core/file/link_spec.rb:14
                                  Proc#call at kernel/core/context.rb:262
                              SpecRunner#it at spec/mini_rspec.rb:337
                                    main.it at spec/mini_rspec.rb:369
                            main.__script__ at spec/core/file/link_spec.rb:24
                              main.platform at ./spec/core/file/../../spec_helper.rb:96
                            main.__script__ at spec/core/file/link_spec.rb:30
                                  Proc#call at kernel/core/context.rb:262
                        SpecRunner#describe at spec/mini_rspec.rb:347
                              main.describe at spec/mini_rspec.rb:365
                            main.__script__ at spec/core/file/link_spec.rb:3
                                  main.load at kernel/core/compile.rb:78
                       main.__eval_script__ at (eval):8
                                 Array#each at kernel/core/array.rb:526
                      Integer(Fixnum)#times at kernel/core/integer.rb:19
                                 Array#each at kernel/core/array.rb:526
                       main.__eval_script__ at (eval):5
                    CompiledMethod#activate at kernel/core/compiled_method.rb:110
                            Compile.execute at kernel/core/compile.rb:34
                            main.__script__ at kernel/loader.rb:170
    ..snip..
    $> 

From the stacktraces we can see:

    No method 'link' on an instance of Class.

indicates that File.link doesn't even exist inside the current implementation of File.

## Design

The corresponding source file to implement File.link is in kernel/core/file.rb:

<filter:jscode lang="ruby">
# depends on: io.rb

class File < IO
  ..snip..

  def self.new(path, mode)
    return open_with_mode(path, mode)
  end
    
  def self.open(path, mode="r")
    raise Errno::ENOENT if mode == "r" and not exists?(path)
    
    f = open_with_mode(path, mode)
    return f unless block_given?

    begin
      yield f
    ensure
      f.close unless f.closed?
    end
  end
  
  def self.exist?(path)
    out = Stat.stat(path, true)
    if out.kind_of? Stat
      return true
    else
      return false
    end
  end

  def self.file?(path)
    st = Stat.stat(path, true)
    return false unless st.kind_of? Stat
    st.kind == :file
  end

  ..snip..
end
</filter:jscode>

Here we see methods implementing various parts of the File API. The above methods show the implementation of File.new, File.open, File.exist? and File.file? (to compare MRI's implementation of the above methods check the file.c source file in the Ruby tar.gz source archive).

Lets look a first implementation of File.link. The primary behaviour of File.link is to create a hard link between two filenames. To do this we need to invoke the link(2) system call on the underlying operating system to create the link.

A quick examination of the link(2) man page yields:

    $> man 2 link

    LINK(2)			    BSD System Calls Manual		       LINK(2)

    NAME
         link -- make a hard file link

    SYNOPSIS
         #include <unistd.h>

         int
         link(const char *name1, const char *name2);

    DESCRIPTION
         The link() function call atomically creates the specified directory entry
         (hard link) name2 with the attributes of the underlying object pointed at
         by name1 If the link is successful: the link count of the underlying
         object is incremented; name1 and name2 share equal access and rights to
         the underlying object.

         ..snip..

    RETURN VALUES
         Upon successful completion, a value of 0 is returned.  Otherwise, a value
         of -1 is returned and errno is set to indicate the error.

         ..snip..

    STANDARDS
         The link() function is expected to conform to IEEE Std 1003.1-1988
         (``POSIX.1'').
          
According to the man page, link(2) accepts the source and target of the symlink as paramaters, and returns an integer indicating success or failure.

## FFI

To invoke link(2) we need to add a new method to the _ffi_ layer inside of Rubinius. _ffi_ stands for 'foreign function interface', and it's a really neat way of being able to interact with system calls on the underlying operating system without needing to write a lot of stub or native integration code.

ffi bindings are compiled into the platform.rba archive, and since link(2) conforms to a POSIX standard the file we need to modify is kernel/platform/posix.rb.

Opening kernel/platform/posix.rb we'll see blocks of code such as the following inside the Platform::POSIX module:

<filter:jscode lang="ruby">
  # file system
  attach_function nil, 'access', [:string, :int], :int
  attach_function nil, 'chmod',  [:string, :int], :int
  attach_function nil, 'fchmod', [:int, :int], :int
  attach_function nil, 'unlink', [:string], :int
  attach_function nil, 'getcwd', [:string, :int], :string
  attach_function nil, 'umask', [:int], :int
</filter:jscode>

This code dynamically attaches methods to the module, and specifies the parameter types and return values of each method.

The general format of the 'attach_function' method is as follows:

  __attach_function___ library, __method name__, [ parameters ], return value
  
  * library, library name to load dynamically, nil otherwise
  * name, name of the method to attach, this is also the name the method will be available as inside the module
  * parameters, array of symbols identifying the types this method accepts as parameters
  * return value, type of the return value

(_attach_function_ can also accept several other formats of parameters, please take a closer look at kernel/platform/ffi.rb for more details)

Symbols are defined for most primitive types, ie: :short, :int, :long, :string, :char, etc, which can be used in the parameter list and return value specifier.

Following the examples above, link(2) can be attached to the Platform::POSIX module with one line of code:

<filter:jscode lang="ruby">
  attach_function nil, 'link', [:string, :string], :int
</filter:jscode>

After adding this line of code to the Platform::POSIX module, we need to update the platform.rba archive to ensure it now includes knowledge of link(2) system call.

    $> rake build:platform

## Implementation

Now that we have access to the link(2) system call, we can invoke it via ffi from the file module.

Open up kernel/core/file.rb, and in between two existing methods, enter the following code:

<filter:jscode lang="ruby">
  def self.link(from, to)
    Platform::POSIX.link(from, to)
  end
</filter:jscode>

As with the platform archive, we'll need to update the core archive:

    $> rake build:core
  
Let's re-run our specifications to see if it passes:

    $> bin/mspec -f s spec/core/file/link_spec.rb

    File.link
    - link a file with another 
    - raise an exception if the target already exists (ERROR - 1)
    - raise an exception if the arguments are of the wrong type or are of the incorrect number


    1)
    File.link raise an exception if the target already exists FAILED
    Expected EEXIST, nothing raised: 
              main.should_raise at ./spec/core/file/../../mspec_helper.rb:27
                main.__script__ at spec/core/file/link_spec.rb:21
                      Proc#call at kernel/core/context.rb:262
                  SpecRunner#it at spec/mini_rspec.rb:337
                        main.it at spec/mini_rspec.rb:369
                main.__script__ at spec/core/file/link_spec.rb:24
                  main.platform at ./spec/core/file/../../spec_helper.rb:96
                main.__script__ at spec/core/file/link_spec.rb:30
                      Proc#call at kernel/core/context.rb:262
            SpecRunner#describe at spec/mini_rspec.rb:347
                  main.describe at spec/mini_rspec.rb:365
                main.__script__ at spec/core/file/link_spec.rb:3
                      main.load at kernel/core/compile.rb:78
           main.__eval_script__ at (eval):8
                     Array#each at kernel/core/array.rb:526
          Integer(Fixnum)#times at kernel/core/integer.rb:19
                     Array#each at kernel/core/array.rb:526
           main.__eval_script__ at (eval):5
        CompiledMethod#activate at kernel/core/compiled_method.rb:110
                Compile.execute at kernel/core/compile.rb:34
                main.__script__ at kernel/loader.rb:170

    3 examples, 1 failures
    $>

We're in better shape, two spec's are now passing, including the link test - we're successfully creating a hard link between 2 filenames, but one spec is still failing in the area of handling error conditions, in particular when the target filename already exists.

Lets update our File.link implementation appropriately:

<filter:jscode lang="ruby">
  def self.link(from, to)
    raise Errno::EEXIST if exists?(to)
    Platform::POSIX.link(from, to)
  end
</filter:jscode>

and naturally, rebuild the core:

    $> rake build:core

and re-run our specification:

    $> bin/mspec -f s spec/core/file/link_spec.rb
    
    File.link
    - link a file with another 
    - raise an exception if the target already exists
    - raise an exception if the arguments are of the wrong type or are of the incorrect number


    3 examples, 0 failures

__hooray__, all link specifications passed.

If the specs for File.link are complete (ie. document all areas of File.link's behaviour), we are ready to submit a patch back to the Rubinius community. Alternatively, if some behaviour is lacking from the specs, we could now iterate through the above process adding a spec to document additional behaviour, and implement it following TDD/BDD practices until all expected behaviour has been added.

## Patch

To create a patch we can use git and issue the command:

    $> git diff > file_link.diff
    
This will create a patch for us containing the changes we made across the entire Rubinius project. We can then send this back to the community for inclusion into the official Rubinius repository, by submitting it in a [Rubinius Lighthouse ticket](http://rubinius.lighthouseapp.com/projects/5089-rubinius/overview).

## Summary

We've stepped through the process of implementing a feature in Rubinius by examining the behaviour of a particular method via it's corresponding specification tests. As part of the implementation we've added a binding to an underlying operating system call via the ffi layer in Rubinius, and then called upon that binding in the class where the functionality is expected.

We then ensured that all required behaviour including error conditions have been met by making sure the spec test suite passes. Finally we've created a patch using git that we can submit back to the Rubinius project via lighthouse.

Implementing a feature in Rubinius can certainly be as straightforward and as easy as what we've seen above. There's many specifications that have been written that don't have corresponding implementations, so pick a class, check it's specs, write an implementation and join in on building a fantastic, extendable and awesome Ruby virtual machine! :)
