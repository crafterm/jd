For the those dual personality developers like myself who love [Ruby](http://www.ruby-lang.org/), [Rails](http://www.rails.com/) and other awesome Ruby tools, but also get a big kick out of [Mac](http://www.apple.com/macosx) and [iPhone](http://www.apple.com/iphone/) development, [MacRuby](http://www.macruby.org/) is a really exciting project worth taking a look at. Originally a port of Ruby 1.9 to the Cocoa/Foundation frameworks under Mac OSX, MacRuby is now a fully fledged Ruby environment, with an [LLVM](http://www.llvm.org/) based interpreter and DSL driven UI toolkit.

MacRuby is still under active development, and isn't finished yet, but it's Ruby and standard library compatibility is already quite impressive.

From the perspective of Ruby development, MacRuby can be used to build and run your Ruby and when supported Rails applications. From the perspective of a Mac applications developer, MacRuby can be used to build fully-fledged OSX desktop applications that interface with all the usual Mac development frameworks such as Core Data, Core Image and Cocoa, etc. User interfaces can be designed using Interface Builder, or using [HotCocoa](http://www.macruby.org/trac/wiki/HotCocoa), a Ruby based DSL for describing Cocoa based UI's.

Technically, MacRuby is implemented using the Objective-C common runtime and garbage collector, and the Core Foundation framework. This means that under MacRuby, Ruby objects are NSObjects (eg. a Ruby String is a NSString, likewise Ruby Hashes are NSDictionary's, without any bindings or conversion required), Ruby classes are Objective-C classes, fully interoperable and interchangeable with each other, and instead of using the Ruby 1.9 garbage collector, the Objective-C 2.0 garbage collector is in full effect.

Most recently with MacRuby 0.5+ and the current development version of MacRuby, the YARV based interpreter has been removed and a new LLVM code generating interpreter has been implemented for performance and further optimisations down the track.

In this particular post I'll work through the installation of MacRuby on your system, several follow up posts will discuss developing applications using MacRuby for Ruby and OSX desktop developers.

### Installing

To get MacRuby running on your machine you currently need to build and install it from source. The build process is straightforward, but does take a bit of time. I'll also assume you have the latest version of XCode installed. Here's what you need to do.

#### Building LLVM

[LLVM](http://www.llvm.org) is required to build the latest MacRuby source, in particular a *specific revision* of LLVM for compatibility reasons, so even if you have it installed already as part of Snow Leopard or Ports, you might need to build it again. The particular revision required is 89156.

LLVM is hosted at [http://www.llvm.org](http://www.llvm.org) in Subversion, however personally I found it much easier to check out using a [git](http://www.git-scm.org/) mirror of the repository rather than attempt it from SVN (which for me took well over an hour just for the checkout that failed before completion resulting in a hosed source tree).

To checkout LLVM using git, and create a branch you can build, based off the right SVN revision number, perform the following commands:

    $> git clone git://repo.or.cz/llvm.git
    $> cd llvm
    $> git checkout -b macruby-reliable 39a0f07ef82b6cc70ce87c038620921d87297ced
    $> env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ ./configure --enable-bindings=none --enable-optimized --with-llvmgccdir=/tmp
    $> env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ make
    $> sudo env UNIVERSAL=1 UNIVERSAL_ARCH="i386 x86_64" CC=/usr/bin/gcc CXX=/usr/bin/g++ make install

Note that *39a0f07ef82b6cc70ce87c038620921d87297ced* above corresponds to the git commit hash of svn commit 89156, you can tell this by looking at the output of git log and searching for 89156 in the git-svn-id section of the log message.

Alternatively, if you really need to check out llvm using Subversion, you can use the following command:

    svn co -r 89156 https://llvm.org/svn/llvm*project/llvm/trunk llvm

Compiling and installing LLVM will take a while (45 minutes or more depending on your system), feel free to grab a cup of coffee - I had a nice Cappuccino:

    2719.14 real      2429.54 user       183.13 sys


#### Building MacRuby

After installing LLVM you can now go ahead and build MacRuby itself. MacRuby now has an official git repository you can use to check out the source from. There is also an [SVN repository](http://svn.macosforge.org/repository/ruby/MacRuby/trunk/) however I'll always favour git over Subversion:

    $> git clone git://git.macruby.org/macruby/MacRuby.git
    $> cd MacRuby
    $> rake
    ....
    /usr/bin/install -c -m 0755 libyaml.bundle /Library/Frameworks/MacRuby.framework/Versions/0.6/usr/lib/ruby/site_ruby/1.9.0/universal-darwin9.0
    cd ext/fcntl
    /usr/bin/make top_srcdir=../.. ruby="../../miniruby -I../.. -I../../lib" extout=../../.ext hdrdir=../../include arch_hdrdir=../../include install
    /usr/bin/install -c -m 0755 fcntl.bundle /Library/Frameworks/MacRuby.framework/Versions/0.6/usr/lib/ruby/site_ruby/1.9.0/universal-darwin9.0
    cd ext/zlib
    /usr/bin/make top_srcdir=../.. ruby="../../miniruby -I../.. -I../../lib" extout=../../.ext hdrdir=../../include arch_hdrdir=../../include install
    /usr/bin/install -c -m 0755 zlib.bundle /Library/Frameworks/MacRuby.framework/Versions/0.6/usr/lib/ruby/site_ruby/1.9.0/universal-darwin9.0
    ./miniruby instruby.rb --make="/usr/bin/make" --dest-dir="" --extout=".ext" --mflags="" --make-flags="" --data-mode=0644 --prog-mode=0755 --installed-list .installed.list --mantype="doc" --sym-dest-dir="/usr/local"
    installing binary commands
    installing command scripts
    installing library scripts
    installing headers
    installing manpages
    installing data files
    installing extension objects
    installing extension scripts
    installing Xcode templates
    installing Xcode 3.1 templates
    installing samples
    installing framework
    installing IB support
    $> sudo rake install

After installing you can test your MacRuby build by using the bundled spec suite:

    $> rake spec:ci

Please note that this installs the latest version of MacRuby under development which is a moving target, however being on the bleeding edge means you can update to the latest source at any time with the latest features and fixes, and makes it much easier for contributing back to the project with patches, etc.

Later, if you'd like to update your installation, just return to the source directory, update your source from the git repository and reinstall.

    $> git pull origin master
    $> rake
    $> sudo rake install

### MacRuby Usage

Now that you have MacRuby installed, you can start using it. gems, ri, irb, etc, are all provided as part of your MacRuby installation with a mac* prefix so they don't conflict with your existing MRI based installation (eg. macri, macirb, macgem, etc). In addition to this further interesting extensions such as XCode templates are included to get started building graphical Cocoa based apps using Interface Builder, etc.

    $> macruby -v
    MacRuby version 0.6 (ruby 1.9.0) [universal-darwin10.0, x86_64]

    $> macirb
    irb(main):001:0> puts "Hello World"
    Hello World
    => nil
    irb(main):002:0>

### Summary

We've stepped through the installation of the latest version of MacRuby on your system, including it's primary dependency LLVM, and described how to familiarise yourself with its environment. In future posts, I'll write further about how to get started creating Cocoa applications using Mac OSX technologies such as XIBs, Bindings, Core Data, and Core Image with your apps, and also how to use [HotCocoa](http://www.macruby.org/trac/wiki/HotCocoa), the nice and concise Ruby DSL for building OSX UI's in Ruby.

If you can't wait till then there's a few further resources I'd recommend taking a look at:

  1. The MacRuby [site](http://www.macruby.org)
  2. The MacRuby [Example](http://svn.macosforge.org/repository/ruby/MacRuby/trunk/sample-macruby/) Applications
  3. Rich Kilmer's MacRuby and HotCocoa [presentation](http://www.fngtps.com/2009/06/ruby-on-os-x-conference-videos) from the [Ruby on OSX](http://rubyonosx.com/) conference in Amsterdam

There's also [@macruby](http://twitter.com/macruby) on Twitter where regular updates are posted, an IRC channel, and two [mailing lists](https://www.macruby.org/contact-us.html). I also follow the Github [mirrors](http://github.com/MacRuby/MacRuby.git) to see each commit that's made to the MacRuby source, together with all the other projects I'm actively following.

Looking forward to writing more MacRuby posts in the future, enjoy MacRuby!

- **Updated** to include newer LLVM revisions and MacRuby 0.6 release (25th May 2010)
