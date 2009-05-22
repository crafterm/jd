[Rubinius](http://rubini.us/) is an alternate implementation of the [Ruby](http://www.ruby-lang.org/en/) virtual machine, loosely based on the architecture and implementation of [Smalltalk-80](http://en.wikipedia.org/wiki/Smalltalk).

The primary difference between Rubinius and MRI (aka Matz Ruby) is that it's modeled around the design of a small, light and fast C kernel, with the surrounding language, libraries and classes implemented in the target language, Ruby. MRI on the other hand, is a larger body of C code.

Rubinius also compiles Ruby classes into byte code before execution and also includes an RSpec test suite that (when complete) documents the Ruby language, core library and Rubinius compiler.

> "what can be written in Ruby, will be"

The focus on using Ruby where possible opens the implementation up to a much wider audience of contributors, and I certainly encourage you to take a look and implement a few core library methods or write some RSpec tests. The barrier of entry is quite low, some methods can even be implemented with a single line of code.

The Rubinius team have published several point releases in the past few months, however the latest and greatest version of Rubinius can be retrieved by checking out the project from source code control.

Recently, Rubinius switched source code control from using Subversion to Git. In this article we'll step through the process of checking out Rubinius, building it, and examining the projects layout. In a future article we'll look at implementing a simple method to step through the process of building a patch that can be submitted back to the project.

## Checking out Rubinius

Since Rubinius is managed by Git, you'll need to install it for your platform first. The Git home page is http://git.or.cz/, which has the Git source, and also hosts binary packages for several platforms. I personally used [Fink](http://finkproject.org/) to install Git ([macports](http://www.macports.org/) also has a package for it, as does many popular Linux distributions).

Git provides a fully distributed development experience. When you check out a project using Git, you are actually cloning an upstream repository which gives you local access to all history and changes within the project. This means you can work on Rubinius when offline, and your source code control system isn't limited by network bandwidth or connectivity.

Distributed development using Git often works with developers 'pulling' changes from each other (such as the Linux Kernel), without there being a central repository where modifications are sent to, Rubinius on the other hand uses Git in a similar fashion to Subversion where a central repository hosts the latest changes, and all developers 'pull' changes from that. To check out the latest source from this central repository, run the following command:

  $> git clone git://git.rubini.us/code rubinius

This will print some interesting output while checking out the source. Note that since you're obtaining a full copy of the repository it will take slightly longer than Subversion which normally gives you the latest versions of all source files.

  $> time git clone git://git.rubini.us/code rubinius
  Initialized empty Git repository in /tmp/rubinius/.git/
  remote: Generating pack...
  remote: Done counting 24773 objects.
  remote: Deltifying 24773 objects...
  remote:  100% (24773/24773) done
  Indexing 24773 objects...
  remote: Total 24773 (delta 15683), reused 22174 (delta 13918)
   100% (24773/24773) done
  Resolving 15683 deltas...
   100% (15683/15683) done
  Checking 4286 files out...
   100% (4286/4286) done

  real    7m8.927s
  user    0m5.006s
  sys     0m2.964s
  $>

## Building Rubinius

Before building Rubinius ensure that you have installed any required dependencies, these are listed in the INSTALL file included in the root Rubinius directory, currently this includes:

* GCC version 4.x http://gcc.gnu.org/
* GNU Bison http://www.gnu.org/software/bison/
* gmake (GNU Make) http://savannah.gnu.org/projects/make/
* pkg-config (configuration tool) http://pkgconfig.freedesktop.org/
* glib2 version >= 2.10 (Gtk2 base libs) http://www.gtk.org/
* libtool version >= 1.5 http://www.gnu.org/software/libtool/
* Ruby version >= 1.8.4 (the Ruby language) http://www.ruby-lang.org/
* RubyGems (Ruby package manager) http://www.rubygems.org/
* Git (source control used by rubinius) http://git.or.cz/
* zip and unzip commands (archiving) http://www.info-zip.org

Once these are installed, building Rubinius is straightforward by running 'configure' and finally 'make':

  $> cd rubinius
  $> ./configure
  Rubinius is configured.
  $> make
  cd shotgun; make rubinius
  cd external_libs/libtommath; make
  cc -I./ -Wall -W -Wshadow -Wsign-compare -fPIC -O3 -funroll-loops -fomit-frame-pointer   -c -o bncore.o bncore.c
  cc -I./ -Wall -W -Wshadow -Wsign-compare -fPIC -O3 -funroll-loops -fomit-frame-pointer   -c -o bn_mp_init.o bn_mp_init.c
  cc -I./ -Wall -W -Wshadow -Wsign-compare -fPIC -O3 -funroll-loops -fomit-frame-pointer   -c -o bn_mp_clear.o bn_mp_clear.c
  cc -I./ -Wall -W -Wshadow -Wsign-compare -fPIC -O3 -funroll-loops -fomit-frame-pointer   -c -o bn_mp_exch.o bn_mp_exch.c
  cc -I./ -Wall -W -Wshadow -Wsign-compare -fPIC -O3 -funroll-loops -fomit-frame-pointer   -c -o bn_mp_grow.o bn_mp_grow.c
  cc -I./ -Wall -W -Wshadow -Wsign-compare -fPIC -O3 -funroll-loops -fomit-frame-pointer   -c -o bn_mp_shrink.o bn_mp_shrink.c
  cc -I./ -Wall -W -Wshadow -Wsign-compare -fPIC -O3 -funroll-loops -fomit-frame-pointer   -c -o bn_mp_clamp.o bn_mp_clamp.c
  cc -I./ -Wall -W -Wshadow -Wsign-compare -fPIC -O3 -funroll-loops -fomit-frame-pointer   -c -o bn_mp_zero.o bn_mp_zero.c
  cc -I./ -Wall -W -Wshadow -Wsign-compare -fPIC -O3 -funroll-loops -fomit-frame-pointer   -c -o bn_mp_set.o bn_mp_set.c
  ...snip...
  CC string.o
  CC strlcat.o
  CC strlcpy.o
  CC subtend/PortableUContext.o
  CC subtend/ffi.o
  CC subtend/handle.o
  CC subtend/library.o
  CC subtend/nmc.o
  CC subtend/nmethod.o
  CC subtend/ruby.o
  CC subtend/setup.o
  CC symbol.o
  CC tuple.o
  CC var_table.o
  CC subtend/PortableUContext_asm.o
  LINK librubinius-0.8.0.dylib
  gcc -Wall -g -ggdb3  -iquote . -iquote lib `pkg-config glib-2.0 --cflags` -Iexternal_libs/libbstring -Iexternal_libs/libcchash `pkg-config glib-2.0 --cflags`  -c -o main.o main.c
  CC rubinius.bin
  ./shotgun/rubinius compile lib/ext/syck
  Cleaning up objects...
  Created rbxext.bundle
  $>
  
From here you can run the Rubinius interpreter which is located in the shotgun directory:

  $> shotgun/rubinius
  sirb(eval):000> 

which will give you an sirb (ie. shotgun irb) prompt. From here you can enter code just as you would in a normal irb session.

You can also run the specs, either individually or as a suite. Rubinius includes a mini-rspec implementation called mspec written in just over a hundred lines of code so that it can self host the full test suite and runner:

  $> bin/mspec -f s spec/core/file/link_spec.rb

The parameter '-f s' indicates that specdoc format should be used for spec result output. In this example we're running the specs associated with the File.link method only.

  $> rake spec

will run all known good specs.

## Directory structure

Browsing the root level Rubinius directory:

  $> ls
  AUTHORS    Makefile   Rakefile   compiler   examples   kernel     shotgun    test
  INSTALL    README     THANKS     configure  extensions lib        spec
  LICENSE    ROADMAP    bin        doc        hashi      runtime    stdlib
  $>

The most important directories can be summarised as follows:

* bin - shell scripts to run mspec, continuous integration, and other tools
* compiler - rubinius compiler implementation
* kernel - platform, bootstrap and core language/library implementation
* runtime - compiled rubinius archives (.rba files) of the compiler, bootstrap and core library
* shotgun - rubinius C interpreter implementation
* spec - rspec style test suite
* stdlib - standard library code imported from Ruby 1.8.

In addition to this there several miscellaneous files including installation, build and license information.

Generally, most Rubinius development action takes place in the kernel, spec and shotgun directories. Inside the kernel directory you'll find a subdirectory for the bootstrap, core and platform components of Rubinius. Bootstrap is initial code that Rubinius reads and uses to start running the compiler and interpreter. Core implements the core language of Ruby, and platform provides the binding to the underlying operating system.

## Integrating changes

Changes can be made to Rubinius using your favourite text editor, compiling changes depends on where you actually make a change.

Modifications made to the low level C interpreter can be built using the 'make' command, changes made to Ruby files (eg. in the kernel directory) can be built using one of the following rake commands:

  rake build:bootstrap    # Compiles the Rubinius bootstrap archive
  rake build:compiler     # Compiles the Rubinius compiler archive
  rake build:core         # Compiles the Rubinius core directory
  rake build:platform     # Compiles the Rubinius platform archive

(to see all available rake tasks run 'rake -T')

These commands will recompile any changes made to the bootstrap, compiler, core and platform source files (located in the kernel bootstrap, compiler core and platform directories respectively) and update the compiled archives in the runtime directory.

Something to be aware of is that the Rubinius compiler uses the bootstrap and core archives itself, so if you accidentally introduce a defect and break a class such as File, Hash, or Array, etc, it's quite likely the compiler will no longer work, leaving you in a state where you can't recompile a fix to the breakage. To handle this catch-22 situation if you're working on some critical methods, run the 'dev:setup' rake task. 'dev:setup' ensures that compilation occurs with pristine copies of the bootstrap, core, platform archives which will be unaffected in case of an error.

## Summary

So far we've covered checking Rubinius out from source, building and running some simple tests with a brief discussion of the project's layout. In a future article I'll walk through implementing a small method to step through the process of creating a patch that can be submitted back to the Rubinius project. In the mean time, feel free to join the #rubinius IRC channel on irc.freenode.net, and read the forums/pages at http://rubini.us/forums.

