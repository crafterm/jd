Like many of us in the Rails world, I use [attachment\_fu](http://svn.techno-weenie.net/projects/plugins/attachment_fu/README) to handle file uploads in my Rails applications. Attachment\_fu does a great job, in particular with it's ability to scale and generate multiple sized copies of images with various processing back ends including ImageScience, RMagick and MiniMagic, not to mention it's flexible storage options, all from the comfort of a DSL:

<filter:jscode lang="ruby">
has_attachment :content_type => :image, 
               :resize_to    => '640x400',
               :storage      => :file_system, 
               :size         => 1.kilobyte .. 3.megabytes,
               :thumbnails   => { :small => '50x50', :medium => '320x200' }
</filter:jscode>

Working on under Mac OS X though, it's often been a challenge to get these underlying libraries installed. General community consensus is that [RMagick](http://rmagick.rubyforge.org/) leaks memory, and [ImageScience](http://seattlerb.rubyforge.org/ImageScience.html) is built upon [FreeImage](http://freeimage.sourceforge.net/) and [RubyInline](http://www.zenspider.com/ZSS/Products/RubyInline/) which requires a development [environment](http://developer.apple.com/tools/xcode/) to compile, install and run.

As developers [MacPorts](http://www.macports.org/) lets us all build and install these libraries comfortably, however the biggest beef I've had is that under the hood of every recent Mac OS X installation, there's actually a great image processing library already available to us - [Core Image](http://developer.apple.com/macosx/coreimage.html).

### Core Image 

Core Image has been a part of Mac OS X since Tiger and is part of the QuartzCore framework, offering a flexible filter/pipeline based approach to manipulating images via [transforms](http://developer.apple.com/documentation/GraphicsImaging/Reference/CoreImageFilterReference/Reference/reference.html). Once of the most exciting things about Core Image though, is that it processes images using a subset of the [OpenGL Shading Language](http://en.wikipedia.org/wiki/OpenGL_Shading_Language), and when available will use the [GPU](http://en.wikipedia.org/wiki/Graphics_processing_unit) to render, all in accelerated hardware near or in real time! In environments where the available GPU is not supported, Core Image automatically falls back to the CPU for processing seamlessly giving us the best of both worlds.

Until recently, access to Core Image has only been available via languages such as Objective-C. However with the release of Leopard, Ruby has become an officially supported language within XCode, and in particular [RubyCocoa](http://rubycocoa.sourceforge.net/HomePage) is available by default under every Leopard Mac OS X installation (in Tiger it can be installed separately).

So now it's even easier for us to take full advantage of the underlying power of these Cocoa API's, directly from Ruby itself.

### Let's get started!

In this article, I'll describe how to add support for using Core Image as the image processing library within attachment_fu. 

Once we're finished, attachment_fu will handle all your uploads using Core Image for resizing and thumbnail generation (most likely hardware accelerated inside your Mac's GPU), if you have Leopard it won't require any 3rd party library to be installed to work, and it will handle any Mac OS X [supported image format](http://developer.apple.com/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Images/chapter_7_section_3.html#//apple_ref/doc/uid/TP40003290-CH208-BCIIFBJG), which as of 10.5, includes RAW. 

It's even more particularly enticing if you deploy your Rails application to an XServe which includes a Core Image supported GPU.

To do this, we'll need to perform the following steps:

* __Create__ an image manipulation class that uses Core Image
* __Integrate__ this new class into attachment\_fu, by writing a new attachment\_fu processor module
* __Optionally__, update attachment\_fu's automatic image processing list, or rely on using the :processor directive in our has_attachment model definitions.

### Create an image manipulation class that uses Core Image

Our first step is to create a new class that uses Core Image to resize and/or thumbnail a given image. To do this, we'll need to define an API to accept the source image, some new dimensions and specify where the resized version should be rendered to.

Inside of the class, we'll use Core Image Filters to perform the actual work. 

Core Image Filters allow you to create a 'pipeline' of transforms that's performed on a given image. Mac OS X includes many filters by default, allowing you to perform all sorts of effects on your image, but the one we're interested in at the moment is the [Lanczos Scale Transform filter](http://developer.apple.com/documentation/GraphicsImaging/Reference/CoreImageFilterReference/Reference/reference.html#//apple_ref/doc/filter/ci/CILanczosScaleTransform).

The Lanczos Scale Transform produces a high quality, scaled version of the source image using a well defined [algorithm](http://en.wikipedia.org/wiki/Lanczos_resampling). 

In addition to this, we'll pre-process the image with an [Affine Clamp](http://developer.apple.com/documentation/GraphicsImaging/Reference/CoreImageFilterReference/Reference/reference.html#//apple_ref/doc/uid/TP30000136-DontLinkElementID_98) filter which will make the image infinitely big by clamping the image's edges outwards. We do this so that there's no edge imperfections introduced due to rounding/ceiling of dimensions when scaling. After the Lanczos scaling has done it's trick, we then crop the image to our target dimensions for rendering.

Here's an example of how we'll use the classes API:

<filter:jscode lang="ruby">
p = Processor.new OSX::CIImage.from(path_to_image)
p.resize(640, 480)
p.render do |result|
  result.save('resized.jpg', OSX::NSJPEGFileType)
end
</filter:jscode>

__Processor.resize(width, height)__ will perform a hard resize to the given dimensions, where as __Processor.fit(size)__ will resize the image to a scale that fits its aspect ratio. These two methods are provided as attachment_fu includes some extra geometry processing code that lets us use RMagick style geometry stings to specify dimensions as fixed values, percentages, scales, or relative aspect ratio sizes that we'll leverage off.

Here's the actual classes implementation

### vendor/core_image/processor.rb

<filter:jscode lang="ruby">
require 'rubygems'
require 'osx/cocoa'
require 'active_support'

# Copyright (c) Marcus Crafter <crafterm@redartisan.com>
#
class Processor
  
  def initialize(original)
    @original = original
  end
  
  def resize(width, height)
    create_core_image_context(width, height)
    
    scale_x, scale_y = scale(width, height)
    
    @original.affine_clamp :inputTransform => OSX::NSAffineTransform.transform do |clamped|
      clamped.lanczos_scale_transform :inputScale => scale_x > scale_y ? scale_x : scale_y, :inputAspectRatio => scale_x / scale_y do |scaled|
        scaled.crop :inputRectangle => vector(0, 0, width, height) do |cropped|
          @target = cropped
        end
      end
    end
  end
  
  def fit(size)
    original_size = @original.extent.size
    scale = size.to_f / (original_size.width > original_size.height ? original_size.width : original_size.height)
    resize (original_size.width * scale).to_i, (original_size.height * scale).to_i
  end
  
  def render(&block)
    raise "unprocessed image: #{@original}" unless @target
    block.call @target
  end
  
  private
  
    def create_core_image_context(width, height)
  		output = OSX::NSBitmapImageRep.alloc.initWithBitmapDataPlanes_pixelsWide_pixelsHigh_bitsPerSample_samplesPerPixel_hasAlpha_isPlanar_colorSpaceName_bytesPerRow_bitsPerPixel(nil, width, height, 8, 4, true, false, OSX::NSDeviceRGBColorSpace, 0, 0)
  		context = OSX::NSGraphicsContext.graphicsContextWithBitmapImageRep(output)
  		OSX::NSGraphicsContext.setCurrentContext(context)
  		@ci_context = context.CIContext
    end

    def vector(x, y, w, h)
      OSX::CIVector.vectorWithX_Y_Z_W(x, y, w, h)
    end
    
    def scale(width, height)
      original_size = @original.extent.size
      return width.to_f / original_size.width.to_f, height.to_f / original_size.height.to_f
    end
     
end

module OSX
  class CIImage
    include OCObjWrapper
    
    def method_missing_with_filter_processing(sym, *args, &block)
      f = OSX::CIFilter.filterWithName("CI#{sym.to_s.camelize}")
      return method_missing_without_filter_processing(sym, *args, &block) unless f
      
      f.setDefaults if f.respond_to? :setDefaults
      f.setValue_forKey(self, 'inputImage')
      options = args.last.is_a?(Hash) ? args.last : {}
      options.each { |k, v| f.setValue_forKey(v, k.to_s) }
      
      block.call f.valueForKey('outputImage')
    end
    
    alias_method_chain :method_missing, :filter_processing
        
    def save(target, format, properties = nil)
      bitmapRep = OSX::NSBitmapImageRep.alloc.initWithCIImage(self)
      blob = bitmapRep.representationUsingType_properties(format, properties)
      blob.writeToFile_atomically(target, false)
    end
    
    def self.from(filepath)
      OSX::CIImage.imageWithContentsOfURL(OSX::NSURL.fileURLWithPath(filepath))
    end
  end
end
</filter:jscode>

The processor class uses a few Ruby idioms, in particular with the filter processing and rendering code. The filtering code leverages blocks and method_missing to provide a declarative approach to defining filters and their parameters:

<filter:jscode lang="ruby">
@original.affine_clamp :inputTransform => OSX::NSAffineTransform.transform do |clamped|
  clamped.lanczos_scale_transform :inputScale => inputScale, :inputAspectRatio => ratio do |scaled|
    scaled.crop :inputRectangle => vector do |cropped|
      @target = cropped
    end
  end
end
</filter:jscode>

(note that the methods affine\_clamp, lanczos\_scale\_transform and crop don't actually exist on OSX::CIImage, they're applied dynamically)

A few helper methods have also been added to OSX::CoreImage to ease construction and serialization. Rendered output file types can be _NSBMPFileType, NSGIFFileType, NSJPEGFileType, NSPNGFileType, or NSTIFFFileType_. See the XCode API documentation for an [NSBitmapImageRep](http://developer.apple.com/documentation/Cocoa/Reference/ApplicationKit/Classes/NSBitmapImageRep_Class/Reference/Reference.html) class for more information about the various properties for each type.

### Integrating our core image processor into attachment_fu

Now that we have a class that can resize images using Core Image, we just need to integrate it with attachment_fu.

Attachment_fu's design is quite modular, allowing us to add a new image processor via writing a module that's mixed in at runtime.
Essentially we need to define a module within the Technoweenie::AttachmentFu::Processors namespace, that will extend the functionality of the 'process_attachment' method.

The common approach is to do this via alias\_method\_chain, which decorates the existing process_attachment method with new functionality. 

Here's the new module:

### technoweenie/attachment\_fu/processors/core\_image\_processor.rb

<filter:jscode lang="ruby">
require 'core_image/processor'

module Technoweenie # :nodoc:
  module AttachmentFu # :nodoc:
    module Processors
      module CoreImageProcessor
        def self.included(base)
          base.send :extend, ClassMethods
          base.alias_method_chain :process_attachment, :processing
        end
        
        module ClassMethods
          def with_image(file, &block)
            block.call OSX::CIImage.from(file)
          end
        end
                
        protected
          def process_attachment_with_processing
            return unless process_attachment_without_processing
            with_image do |img|
              self.width  = img.extent.size.width  if respond_to?(:width)
              self.height = img.extent.size.height if respond_to?(:height)
              resize_image_or_thumbnail! img
              callback_with_args :after_resize, img
            end if image?
          end

          # Performs the actual resizing operation for a thumbnail
          def resize_image(img, size)
            processor = Processor.new(img)
            size = size.first if size.is_a?(Array) && size.length == 1
            if size.is_a?(Fixnum) || (size.is_a?(Array) && size.first.is_a?(Fixnum))
              if size.is_a?(Fixnum)
                processor.fit(size)
              else
                processor.resize(size[0], size[1])
              end
            else
              new_size = [img.extent.size.width, img.extent.size.height] / size.to_s
              processor.resize(new_size[0], new_size[1])
            end
            
            processor.render do |result|
              self.width  = result.extent.size.width  if respond_to?(:width)
              self.height = result.extent.size.height if respond_to?(:height)
              result.save self.temp_path, OSX::NSJPEGFileType
              self.size = File.size(self.temp_path)
            end
          end          
      end
    end
  end
end
</filter:jscode>

The module brings the core image based processing class we've written above into scope, and then proceeds to define a CoreImageProcessor module within the Technoweenie::AttachmentFu::Processors namespace. When this module is included, it then aliases process\_attachment to add some new functionality, essentially the process\_attachment\_with\_processing and resize_image methods.

Most of the code in this module surrounds calling the processor class' API with the correct resize values based on the range of possible geometry values attachment_fu allows. The ImageScience and RMagick processors look quite similar.

### Update attachment\_fu's automatic image processing list

Attachment_fu includes several processors which are tried in order at startup to work out which image processing engine to use, based on what underlying libraries, etc, are available on your machine.

This step is optional because we can either update this list so that our Core Image processor is part of this selection, or we can specify the processor directly when defining a has_attachment on a model:

<filter:jscode lang="ruby">
has_attachment :content_type => :image, 
               :processor    => :core_image,
               :resize_to    => '640x400',
               :storage      => :file_system, 
               :size         => 1.kilobyte .. 3.megabytes,
               :thumbnails   => { :small => '50x50', :medium => '320x200' }
</filter:jscode>

To update the default list, open up the attachment\_fu.rb source file, and update the @@default_processors class variable from:

<filter:jscode lang="ruby">
module Technoweenie
  module AttachmentFu
    @@default_processors = %w(ImageScience Rmagick MiniMagick)
</filter:jscode>

to:

<filter:jscode lang="ruby">
module Technoweenie
  module AttachmentFu
    @@default_processors = %w(CoreImage ImageScience Rmagick MiniMagick)
</filter:jscode>

which will register the Core Image processor module for inclusion when attachment\_fu searches for image processors.

### Summary

We've created a class that uses Core Image to resize an image to given dimensions, using a high quality Lanczos Scale transform, via RubyCocoa. We've integrated it into attachment\_fu by creating a new processor module that can be specified in the default image processing search list, or directly in a has_attachment definition. 

### I want it!

To make things easy, I've created a git [repository](http://git.redartisan.com/?p=af_ci.git;a=summary) that includes all of the above files so you can keep up to date, and the project format is in a structure you can export directly into your attachment\_fu installation. To access the source, use the following command:

    $> git clone git://git.redartisan.com/af_ci.git

This will check out the attachment_fu core image project that you can copy across into your attachment\_fu installation (or perform a nice git export of the source directly).

Once you've installed the source files in your attachment\_fu plugin, apply the supplied patch to update attachment\_fu's list of supported image processors. You'll need to restart your Rails application to reload the plugin, after which you'll be using Core Image to process attachments!

### Future

I have several further enhancements and ideas surrounding the core image processor which I'll talk about in further articles - if you have any improvements to the code, patches are also more than welcome. Enjoy!

### [Update]

To facilitate updates to the code, I've imported the source into a git [repository](http://git.redartisan.com/?p=af_ci.git;a=summary) rather than distribute via the tar/gz the original post referenced.

### [Update II]

Now that Technoweenie has imported his sources into github, I've created a child [attachment_fu](http://github.com/crafterm/attachment_fu/tree/master) repository that includes all of the above updates to use Core Image with Attachment Fu.

