<div style="float:right; margin-left: 10px">
  <img src="/assets/2011/1/24/1-screenshot.jpg" width="300px" style="border:1px solid grey">
</div>

Recently, [Captivate](http://captivateapp.com?utm_source=redartisan.com&utm_medium=post&utm_campaign=knowledge-sharing), an iPad application
I've been working on with fellow developers [Justin
French](http://www.justinfrench.com) and [Gareth
Townsend](http://www.garethtownsend.com) was accepted into the
[iTunes AppStore](http://itunes.apple.com/au/app/captivate/id393073363?mt=8)!

Captivate is an entertainment/photography application for browsing
photos on Flickr. Photos are grouped by popular and common tag
names which the user can browse and select. Within each tag exists up
to 3 clusters of content covering the most popular streams of photos
for that tag. Each photo can be viewed similar to Photos.app,
and with photo and mapping information displayed when
available.

Social networking is also inbuilt allowing you to post
photos you like to Twitter, Facebook, Tumbler, or simply navigate
through to the photographers Flickr page direct.

The application was in development for several months, this article
explores some of the discoveries I learned or were reinforced to me
during that journey.

#### Teamwork

_"The whole is more than the sum of its parts"_ - Aristotle

Having a team means you can divide things up and gain focus with a
common vision. The productivity you gain from this focus is far
higher than if you had to deal with everything yourself.

The skillset our team had included code writing and UI/UX design,
which helped immensely as I was able to focus purely on development, while
others could delve into the UI/UX we'd designed and provide feedback to
ensure the feel of the application fit within the iPad experience.

There was also a lot more than just code to write, Captivate has 5
sets of API keys,
[Flickr](http://www.flickr.com/services/apps/72157624835987947/) &
Facebook App Garden submissions, a dedicated
[website](http://captivateapp.com?utm_source=redartisan.com&utm_medium=post&utm_campaign=knowledge-sharing),
[Twitter](http://twitter.com/captivateapp) account, plus the usual
AppStore ad-hoc and app store submission process requirements
including description text, screenshots, crafted tags, etc. Now
released, there's also support email and ongoing maintenance.


#### Tweak iteratively

We designed the look of the application upfront with screen and UI flow
(back of the napkin style) sketches, an application design statement,
following Apple's recommend process.

Once into implementation though, we ran the app on the device together
to check the *feel* of what had been built extremely often (at least every
day, sometimes every few commits).

I found this particularly important as we caught quite a few little
things in the design & implementation early on that were only visible once
there was something to use - not just features that did or didn't
work, but nuances such as animation timings, wifi/3g network latency,
UIKit scrolling and drawing performance, etc.

Running the code often allowed us to notice these things sooner rather
than later, and nip them in the bud while the code that introduced
them was fresh in the mind.

#### UIScrollView Journey

UIScrollView is worthy of its own Bachelor's Degree - it's ubiquitous,
almost in all iOS applications, but its a tricky class to master. In
our application it is everywhere, particularly when viewing/swiping
full screen photos images a la Photos.app.

Captivate's development taught me a lot about UIScrollView,
particularly how complex things can become when you're supporting
swipe & pinch gestures, rotation and subview auto-resizing, and
asynchronous loading across infinite content, all at the same
time.

Apple does have some examples and WWDC video material in this area
that are quite helpful, however even those don't cover all these
aspects in one application - there's naunces and trickyness everywhere.

The journey was so intense, that after learning what we needed for
Captivate, I shared the knoweldge as part of a
[presentation](/2010/10/30/uiscrollview-giggles-glory)
to our local Cocoaheads chapter, which was recorded and is available online.

Learning how to wield UIScrollView like a Jedi is a worthwhile
pursuit, and one I recommend all iOS developers follow. It will save
you mountains of time and stress down the track when you attempt to
use it on a time dependent project.

#### Local Network

During development of any iOS application, you'll inevitably have to
implement some feature you've never done before (after all these are
the things that distinguish our applications out from the
crowd), or you'll hit the preverbial wall debugging an issue and need
some inspiration.

This is where having a network of developers really helps, as it's
more likely someone from this group will have done something similar,
or at least have experience with the API, an open source library or
debugging technique required.

Find your network, go to your local Cocoaheads (or start one if one
doesn't exist), attend WWDC, hack nights, and even related technology
events such as Railscamp - apart from having an incrediblely awesome
time and learning so much from all the knowledge being shared, you'll
meet some sensational people you can bounce ideas off, learn from
and even potentially work with - not to mention these people will
probably become good friends for years to come.

In our case, having local experts such as
[Matt](http://cocoawithlove.com/),
[Sean](http://www.ittybittyapps.com/) and [Luke](http://tupps.com/)
really helped with bouncing ideas, learning special debugging
techniques and the intricacies of various iOS frameworks!

#### Open Source Libraries & Tools

Coming from a [Ruby on Rails](http://rubyonrails.org/) background,
using open source frameworks in an iOS app came as second nature -
there's a wealth of excellent code out there that can save you days if
not months of work in development and/or debugging. Try to keep on
track by focusing on the business logic you app does, and if you find
yourself going off on a tangent building something that doesn't
directly relate to your features - step back and see if it's been
solved already.

In our case, we leveraged several well known iOS open source
frameworks that really gave us a step up in terms of focus on what
specific features our application offered, such as
[ObjectiveFlickr](https://github.com/lukhnos/objectiveflickr),
[ShareKit](http://www.getsharekit.com/),
[asi-http-request](http://allseeing-i.com/ASIHTTPRequest/) to name a
few.

During Captivate's development I also learnt a lot about Apple's
toolset and how beneficial they can be. Instruments, Shark, Xcode,
etc, are all really useful, as are some of the smaller non-descript
tools such as *symbolicatecrash* to help cross reference crash
logs. Git and GitHub was also a winner as its been on many other projects in the past.

#### Summary

The list could go on but I'll leave it there for this
post. [Captivate](http://captivateapp.com?utm_source=redartisan.com&utm_medium=post&utm_campaign=knowledge-sharing)
is up on the AppStore now, and we've just started with some of the
features we'll be implementing over the next few months - we'd love to
hear any feedback and any ideas you might have about how to improve it.

