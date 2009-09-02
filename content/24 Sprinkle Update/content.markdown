[Sprinkle](http://github.com/crafterm/sprinkle), the new provisioning tool I recently [released](http://redartisan.com/2008/5/27/sprinkle-intro) has been progressing really well over the past few months. Its been great to see the focus of Sprinkle to succinctly describe software installation via an elegant Ruby DSL language improve so well.

Last Thursday at our monthly Melbourne Ruby User Group meetup, I had the pleasure of demonstrating Sprinkle to the local community. I've uploaded the slides for those interested:

<div style="width:425px;text-align:left" id="__ss_539628"><object style="margin:0px" width="425" height="355"><param name="movie" value="http://static.slideshare.net/swf/ssplayer2.swf?doc=sprinkle-1217728084671199-8&stripped_title=sprinkle" /><param name="allowFullScreen" value="true"/><param name="allowScriptAccess" value="always"/><embed src="http://static.slideshare.net/swf/ssplayer2.swf?doc=sprinkle-1217728084671199-8&stripped_title=sprinkle" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="355"></embed></object></div>

Gem packages for Sprinkle are available from both [GitHub](http://github.com/crafterm/sprinkle) and [Rubyforge](http://rubyforge.org/projects/sprinkle/), and include several new features that have been added sine my [original](http://redartisan.com/2008/5/27/sprinkle-intro) post about the project.

__Deployment/command delivery__

* [Support](http://github.com/crafterm/sprinkle/tree/master/lib/sprinkle/actors/vlad.rb) for Vlad in addition to Capistrano, allowing you to leverage upon your existing Vlad configuration

* Direct or gateway tunneled net/ssh connection [support](http://github.com/crafterm/sprinkle/tree/master/lib/sprinkle/actors/ssh.rb), allowing you to configure Sprinkle to communicate with remote hosts via net/ssh directly if you desire

* [Support](http://github.com/crafterm/sprinkle/tree/master/lib/sprinkle/actors/local.rb) for provisioning your local machine using Sprinkle by running any commands locally

__Installers__

* [Support](http://github.com/crafterm/sprinkle/tree/master/lib/sprinkle/verify.rb) for automatically verifying installations pre- and post-install to detect any installation errors, and also to optimize the installation order to skip packages already installed.

* [Support](http://github.com/crafterm/sprinkle/tree/master/lib/sprinkle/installers/apt.rb) for installing build dependencies of APT packages

* [Support](http://github.com/crafterm/sprinkle/tree/master/lib/sprinkle/installers/rpm.rb) for installing RPM packages

* [Support](http://github.com/crafterm/sprinkle/tree/master/lib/sprinkle/installers/gem.rb) for installing GEM packages from a specific remote repository (eg. github) and into a specific local repository

__Documentation__

* Full RDoc coverage across all classes, also published online

* [New](http://blog.citrusbyte.com/2008/7/18/automate-your-rails-deployment) blog posts & screencast demonstrating Sprinkle

__Examples__

* Many new [examples](http://github.com/crafterm/sprinkle/tree/master/examples) have been contributed showing several ways of using Sprinkle to provision packages from Git, Ruby, Rails, Sphinx, through to Phusion, etc.

Plus many other contributions from people around the world helping with specs, bugs and other improvements which has been great.

I'd really like to thank everyone who has jumped in and helped with the project in any way over the past few months, I really appreciate your support!