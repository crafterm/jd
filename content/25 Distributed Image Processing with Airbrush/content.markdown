[Airbrush](http://github.com/square-circle-triangle/airbrush) is a lightweight distributed processing tool, that Rails applications can use to communicate with and offload heavy processing of images, and/or other tasks while they continue processing requests.

Early this year, one of my [clients](http://www.sct.com.au/) started experiencing issues with their Rails application that managed the content for approximately 40 sites. The problem was in the area of image processing, with *very* large images, many several hundred megabytes in size that would be uploaded by the site's administrators for publishing on various sorts of media.

When an image was uploaded several previews were being generated, and this process was bringing the system to a halt, consuming all resources of the Mongrel processing the request, to the point where the virtual server hosting that process would kill it off as a rampant process. Even testing some of the offending images would bring our MacBook Pro's to a grinding halt, with memory use soaring into swap, causing everything to slow down to a snails pace.

We employed various tools for the platforms we were testing on, *strace* under Linux and later [*dtrace*](http://redartisan.com/2008/5/18/dtrace-ruby) under Mac OS X. We noticed one example image, 10mb in size, would allocate 700mb of memory while it was being read by the image library (RMagick 2.x at the time). Image Science and even Quartz on my Mac OS X Tiger install exhibited similar behaviour.

After much research and testing, we found many of the offending images to be in non-RGB colour profiles, and to include all sorts of meta data (one even included an entire XML formatted Mac OSX plist file in its header). Installing profile management and pre-processing metadata alleviated much of the memory exhaustion pain.

The production environment consisted of many smaller Ubuntu Linux virtual private servers (~256mb ram, etc), so we decided to isolate the processing of images into a dedicated slice, so that could be shared across all the application servers, and could be configured to any specifications we required to handle the scale content being rendered.

This gave birth to Airbrush, which has been in use now for several months now with great success, and [Square Circle Triangle](http://www.sct.com.au/), the client who paid for its development, has allowed us to [open source](http://github.com/square-circle-triangle/airbrush) Airbrush for all to use under the MIT license.

Airbrush was designed to abstract the three main roles in its architecture - the listening, the processing and the publishing of results from incoming jobs. This was done primarily to allow us to provide any style of access to Airbrush's services now and in the future (eg. a queuing system, webservice, etc), and to allow processing of any job type, not just related to image processing (eg. bulk emailing, report generation, etc).

Around the time Airbrush was architected, [Starling](http://dev.twitter.com/2008/01/announcing-starling.html), a memcache derived persistent queue implementation was released, and became the perfect fit for Airbrush's first listener implementation.

To get up and running with Airbrush, first install the following gems:

    $> gem install starling airbrush rmagick
    
Then, create a memcache queue using Starling (specifying the queue and pid file locations):

    $> starling -q /var/tmp/starling -P /var/tmp/starling.pid
    I, [2008-11-02T11:58:13.443012 #77820]  INFO -- : Starling STARTUP on 127.0.0.1:22122

Then, start any number of Airbrush server instances:

    $> airbrush -v
    Sun Nov 02 11:58:22 +1100 2008: Accepting incoming jobs

'v' indicates verbose operation, so that you receive extra logging information. Several other options can be passed to Airbrush such as the memcache server location and port, job poll frequency and a log target, run 'airbrush -h' for further details. Both Starling and Airbrush's default to the localhost as the memcache server on port 22122, so if you are running both Starling and Airbrush locally the defaults will be fine.

To send a preview request to an Airbrush server, you can use the example *airbrush-example-client* command included with the Airbrush gem:

    $> airbrush-example-client -i leaves_desktop.jpg -o resized
    Sending leaves_desktop.jpg for preview processing
    
This sends the image 'leaves_desktop.jpg' to be resized into two smaller previews, with filenames starting with 'resized'.

Back on the Airbrush server side, you'll notice some further logging output when this happens:

    Sun Nov 02 12:02:16 +1100 2008: Processing generate-previews
    Sun Nov 02 12:02:18 +1100 2008: Processed previews ({:filename=>"leaves_desktop.jpg", :sizes=>{:small=>[300], :large=>[600]}, :image=>"[FILTERED]"})
    Sun Nov 02 12:02:18 +1100 2008: Published results from generate-previews
    Sun Nov 02 12:02:18 +1100 2008: Processed generate-previews: 0.806346 seconds processing time

Indicating a successful job. Should an error occur, both the client and server will report what happened.

Internally, the API request to create several image previews is:

    client = Airbrush::Client.new(memcache_host)
    client.process(
      'generate-previews', :previews, 
        :image => File.read(OPTIONS[:image]), 
        :sizes => { :small => [300], :large => [600] } )

This creates an instance of the Airbrush client, and instructs it to process a given job via the #process method. The parameters to #process specify a unique job id (also used as the return memcache queue name for any results the job may provide), the job name (:previews in this case), and arguments to the job (two sizes in this example, for the creation of 'small' and 'large' previews, with a longest edge of 300 and 600 pixels respectively). Airbrush will calculate the resultant dimensions using the aspect ratio of the image.

An Airbrush server reads this job request from the Starling memcache queue, processes it and places the results back on the queue for the client to read either immediately, or at a later time.

Processing is a simple Ruby class with method names matching job names, here's an example taken from Airbrush's RMagick based image processor with the *resize* and *previews* job implementations:

    module Airbrush
      module Processors
        module Image
          class Rmagick < ImageProcessor
            filter_params :image # ignore any argument called 'image' in any logging

            def resize(image, width, height = nil)
              width, height = calculate_dimensions(image, width) unless height

              process image do
                change_geometry("#{width}x#{height}") { |cols, rows, image| image.resize!(cols, rows) }
              end
            end
      
            def previews(image, sizes) # sizes => { :small => [200,100], :medium => [400,200], :large => [600,300] }
              sizes.inject(Hash.new) { |m, (k, v)| m[k] = crop_resize(image, *v); m }
            end
      
            # ... snip ...
      
          end
        end
      end
    end

The parameters to each method are extracted from the options has passed in as arguments to the named job (similar to how Merb can extract values from the params[] hash automatically).

The current RMagick based image processor supports resizing, cropping and multiple preview generation, with images in RGB and CMYK colour profiles. 'before' and 'after' filters are also supported to pre or post process images (eg to add a watermark or filter out metadata amongst other things) as well. A Core Image based processor is also available.

The distributed nature of memcache allows us to daisy chain as many airbrush servers as we'd like to handle anticipated load, and we can spread this across any number of VPS or real servers as we'd like (even other platforms such as X-Serve's with dedicated video processing hardware). Another added benefit of using Starling to handle the incoming job queue is that Airbrush servers can be increased/decreased without affecting the queue reliability - even when no Airbrush servers are running, jobs will simply be added to the Starling queue and wait until one is started.

Airbrush is available as a gem on GitHub and Rubyforge, and is under the MIT license. We're excited to see it released, and keen to continue its development. Please also feel free to contact us with any suggestions or ideas to make Airbrush more useful for everyone.

