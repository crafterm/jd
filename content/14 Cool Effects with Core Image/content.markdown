In a previous [article](/2007/12/12/attachment-fu-with-core-image) I described how to use [Core Image](http://developer.apple.com/macosx/coreimage.html) as the backend image processor for [Attachment Fu](http://svn.techno-weenie.net/projects/plugins/attachment_fu/README) in your Rails applications. In that particular article we looked at supporting image scaling and thumbnails to be compatible with the other Attachment Fu backends such as [RMagick](http://rmagick.rubyforge.org/) and [ImageScience](http://seattlerb.rubyforge.org/ImageScience.html).

With Core Image available however, we have an entire range of post processing filters available to use at our fingertips. In this article we'll step through a few of these additional filter options that you can use to post process your images with.

Here's a few examples of what we can do with Core Image post file upload. All of the following examples use the following input image taken in Berlin while at RailsConf EU (also used in the performance measurements [article](/2007/12/16/core-image-performance)):

<img src="http://redartisan.com/assets/2007/12/16/IMG_2990.jpg" />

## Greyscale or Sepia

A scaled version of the source image is cool, but how about an automatic greyscale or sepia version of the image:

### Greyscale

<img src="http://redartisan.com/assets/2007/12/31/berlin-grey.jpg" />

### Sepia

<img src="http://redartisan.com/assets/2007/12/31/berlin-sepia.jpg" />

### Code Fragment

<filter:jscode lang="ruby">
module RedArtisan
  module CoreImage
    module Filters
      module Color
        
        def greyscale(color = nil, intensity = 1.00)
          create_core_image_context(@original.extent.size.width, @original.extent.size.height)
          
          color = OSX::CIColor.colorWithString("1.0 1.0 1.0 1.0") unless color
          
          @original.color_monochrome :inputColor => color, :inputIntensity => intensity do |greyscale|
            @target = greyscale
          end
        end
        
        def sepia(intensity = 1.00)
          create_core_image_context(@original.extent.size.width, @original.extent.size.height)
          
          @original.sepia_tone :inputIntensity => intensity do |sepia|
            @target = sepia
          end
        end
        
      end
    end
  end
end
</filter:jscode>

## Exposure and Noise Control

Another option for us is to automatically adjust exposure and noise parameters upon upload to brighten images up, or remove unwanted noise from lower quality images:

### 1 F-Stop

<img src="http://redartisan.com/assets/2007/12/31/berlin-exposure-adjusted-full-stop.jpg" />

### 2 F-Stops

<img src="http://redartisan.com/assets/2007/12/31/berlin-exposure-adjusted-two-stops.jpg" />

### Noise Removal

<img src="http://redartisan.com/assets/2007/12/31/berlin-noise-reduced.jpg" />

### Code Fragment

<filter:jscode lang="ruby">
module RedArtisan
  module CoreImage
    module Filters
      module Quality
        
        def reduce_noise(level = 0.02, sharpness = 0.4)
          create_core_image_context(@original.extent.size.width, @original.extent.size.height)
          
          @original.noise_reduction :inputNoiseLevel => level, :inputSharpness => sharpness do |noise_reduced|
            @target = noise_reduced
          end
        end
        
        def adjust_exposure(input_ev = 0.5)
          create_core_image_context(@original.extent.size.width, @original.extent.size.height)
          
          @original.exposure_adjust :inputEV => input_ev do |adjusted|
            @target = adjusted
          end          
        end
        
      end
    end
  end
end
</filter:jscode>

## Watermarking

Sometimes we'd like to automatically add a watermark to our images, either with a single watermark image, or as a tiled watermark image:

### Single Watermark

<img src="http://redartisan.com/assets/2007/12/31/berlin-watermarked.jpg" />

### Tiled Watermark

<img src="http://redartisan.com/assets/2007/12/31/berlin-watermarked-tiled.jpg" />

### Code Fragment

<filter:jscode lang="ruby">
module RedArtisan
  module CoreImage
    module Filters
      module Watermark
        
        def watermark(watermark_image, tile = false, strength = 0.1)
          create_core_image_context(@original.extent.size.width, @original.extent.size.height)
          
          if watermark_image.respond_to? :to_str
            watermark_image = OSX::CIImage.from(watermark_image.to_str)
          end
          
          if tile
            tile_transform = OSX::NSAffineTransform.transform
            tile_transform.scaleXBy_yBy 1.0, 1.0
            
            watermark_image.affine_tile :inputTransform => tile_transform do |tiled|
              tiled.crop :inputRectangle => vector(0, 0, @original.extent.size.width, @original.extent.size.height) do |tiled_watermark|
                watermark_image = tiled_watermark
              end
            end
          end
          
          @original.dissolve_transition :inputTargetImage => watermark_image, :inputTime => strength do |watermarked|
            @target = watermarked
          end
        end

      end
    end
  end
end
</filter:jscode>

## Funky Effects

We can also use cool and funky effects used in applications like Photobooth, here's an example using the edge colouring algorithm:

### Edges

<img src="http://redartisan.com/assets/2007/12/31/berlin-edge.jpg" />

### Core Fragment

<filter:jscode lang="ruby">
module RedArtisan
  module CoreImage
    module Filters
      module Effects
        
        def edges(intensity = 1.00)
          create_core_image_context(@original.extent.size.width, @original.extent.size.height)
          
          @original.edges :inputIntensity => intensity do |edged|
            @target = edged
          end
        end

      end
    end
  end
end
</filter:jscode>

The sign artwork works particularly well with this algorithm.

## Core Image Processor

All of the code above is also available as a usable image processor via [git](http://git.redartisan.com/?p=af_ci.git;a=history;f=vendor;hb=HEAD). 

Some examples of using the processor:

<filter:jscode lang="ruby">
require 'red\_artisan/core\_image/processor'

# generate some test output images for various effects

processor = RedArtisan::CoreImage::Processor.new('berlin.jpg')

grey = processor.greyscale
grey.save 'results/berlin-grey.jpg'

sepia = processor.sepia
sepia.save 'results/berlin-sepia.jpg'

watermarked = processor.watermark('watermark_image.png')
watermarked.save 'results/berlin-watermarked.jpg'

watermarked = processor.watermark('watermark_image.png', true)
watermarked.save 'results/berlin-watermarked-tiled.jpg'

noise\_reduced = processor.reduce_noise
noise\_reduced.save 'results/berlin-noise-reduced.jpg'

exposure\_adjusted = processor.adjust_exposure
exposure\_adjusted.save 'results/berlin-exposure-adjusted-half-stop.jpg'

exposure\_adjusted = processor.adjust_exposure(2.0)
exposure\_adjusted.save 'results/berlin-exposure-adjusted-two-stops.jpg'

edge = processor.edges
edge.save 'results/berlin-edge.jpg'
</filter:jscode>

## Summary

The above shows us only a fraction of what can be done with the 100+ filters Core Image provides by [default](http://developer.apple.com/documentation/GraphicsImaging/Reference/CoreImageFilterReference/Reference/reference.html#//apple_ref/doc/uid/TP40004346-CH202-TPXREF101). There's many other filters that let you create all sorts of effects with single and multiple images combined. Enjoy!

