<img src="/assets/2008/1/12/snap1.jpg"/>

During the week a good friend of mine laid down the challenge to work out how to programatically create a screenshot of your Mac OSX desktop. The following article steps through the process of performing this, adding some charm to the operation to create a full desktop snapshot tool using Ruby Cocoa.

Before stepping into the code, I'll first present a small extension module that all code snippets rely upon. It's essentially a small extension to the OSX::CIImage class to simplify loading and saving of image files, and conversions between Core Image and Quartz Image objects (which we'll need later).

### extensions.rb

    module OSX
      class CIImage      
        def save(target, format = OSX::NSJPEGFileType, properties = nil)
          bitmapRep = OSX::NSBitmapImageRep.alloc.initWithCIImage(self)
          blob = bitmapRep.representationUsingType_properties(format, properties)
          blob.writeToFile_atomically(target, false)
        end
    
        def cgimage
          OSX::NSBitmapImageRep.alloc.initWithCIImage(self).CGImage()
        end
    
        def self.from(filepath)
          raise Errno::ENOENT, "No such file or directory - #{filepath}" unless File.exists?(filepath)
          OSX::CIImage.imageWithContentsOfURL(OSX::NSURL.fileURLWithPath(filepath))
        end
      end
    end

### Capturing the Desktop

With our extensions code in place, we can use the new CGWindow API, recently added to Mac OSX 10.5, to snapshot our desktop:

    require 'osx/cocoa'
    require 'extensions'

    class Screen
      def self.capture
        screenshot = OSX::CGWindowListCreateImage(OSX::CGRectInfinite, OSX::KCGWindowListOptionOnScreenOnly, OSX::KCGNullWindowID, OSX::KCGWindowImageDefault)
        OSX::CIImage.imageWithCGImage(screenshot)
      end
    end

    Screen.capture.save('desktop.jpg')

<img src=""/>

This works really well and is only a few lines of code. It's quite fast, in fact the Apple documentation mentions "For capturing pixels, the CGWindow API should demonstrate performance that is equal or better than the techniques used by the OpenGLScreenSnapshot and OpenGLScreenCapture samples". The only thing is that the user has no feedback that an actual screenshot was taken, other than the creation of the target image file.

So, lets build upon this and add some feedback.

### Capturing the Desktop with a Fade operation

What we'll do to make it obvious that a screenshot is being taken, is fade the desktop out to a black colour, take the screenshot of the original desktop content, and fade the desktop back to it's original state. The effect is similar to what OSX does while changing screen resolutions when you attach an external display or a projector to your Mac.

Implementation wise, we'll add a __fade__ operation to our Screen class, that will accept a block of code to perform in between fading the display out and back in again. The relevant Cocoa operations are documented in the Quartz Display Services [guide](http://developer.apple.com/documentation/GraphicsImaging/Conceptual/QuartzDisplayServicesConceptual/Articles/FadeEffects.html#//apple_ref/doc/uid/TP40004232). Essentially we need to invoke CGAcquireDisplayFadeReservation() to obtain a fade reservation token, after which we can invoke CGDisplayFade() to fade the display to a solid colour and back. Once we're done fading, we can release the fade reservation token with CGReleaseDisplayFadeReservation() (or allow it to time out).

    require 'osx/cocoa'
    require 'extensions'

    class Screen
  
      def self.capture
        fade do
          screenshot = OSX::CGWindowListCreateImage(OSX::CGRectInfinite, OSX::KCGWindowListOptionOnScreenOnly, OSX::KCGNullWindowID, OSX::KCGWindowImageDefault)
          OSX::CIImage.imageWithCGImage(screenshot)
        end
      end
  
      private
  
        def self.fade
          err, token = OSX::CGAcquireDisplayFadeReservation(OSX::KCGMaxDisplayReservationInterval)
  
          if err == OSX::KCGErrorSuccess
            begin
              OSX::CGDisplayFade(token, 0.3, OSX::KCGDisplayBlendNormal, OSX::KCGDisplayBlendSolidColor, 0, 0, 0, true)
              return yield if block_given?
            ensure
              OSX::CGDisplayFade(token, 0.3, OSX::KCGDisplayBlendSolidColor, OSX::KCGDisplayBlendNormal, 0, 0, 0, false)
              OSX::CGReleaseDisplayFadeReservation(token)
            end
          end
        end
    end

    Screen.capture.save('desktop.jpg')

### Capturing the Desktop with a Fade and Snap Photo Picture

The fade looks really nice, but since other applications can also perform the same effect, lets embed a small graphic in between the fade of a camera to really show that we're taking a picture of the desktop.

<img src="/assets/2008/1/12/nikon.jpg"/>

To do this, we need to capture the desktop in between the fade operation, and draw directly onto the display, without creating a window or any other graphical decorations. Capturing and drawing directly onto a display are discussed in the Quartz documentation [online](http://developer.apple.com/documentation/GraphicsImaging/Conceptual/QuartzDisplayServicesConceptual/Articles/DisplayCapture.html) also.

Essentially, we need to use __CGDisplayCapture(display)__ to capture a specified display. While it's captured we have exclusive access to the display, and no other application will interfere with it. Then, we can use __CGDisplayGetDrawingContext(display)__ to obtain a drawing context, and __CGContextDrawImage()__ to draw an image directly to the display. Once we're done showing our picture, we can then release our capture of the display using __CGDisplayRelease(display)__.

    require 'osx/cocoa'
    require 'extensions'

    class Screen
  
      def self.capture
        fade do
          screenshot = OSX::CGWindowListCreateImage(OSX::CGRectInfinite, OSX::KCGWindowListOptionOnScreenOnly, OSX::KCGNullWindowID, OSX::KCGWindowImageDefault)
          OSX::CIImage.imageWithCGImage(screenshot)
        end
      end
  
      private
  
        def self.fade
          err, token = OSX::CGAcquireDisplayFadeReservation(OSX::KCGMaxDisplayReservationInterval)
  
          if err == OSX::KCGErrorSuccess
            begin
              OSX::CGDisplayFade(token, 0.3, OSX::KCGDisplayBlendNormal, OSX::KCGDisplayBlendSolidColor, 0, 0, 0, true)
          
              snap(token)
          
              return yield if block_given?
            ensure
              OSX::CGDisplayFade(token, 0.3, OSX::KCGDisplayBlendSolidColor, OSX::KCGDisplayBlendNormal, 0, 0, 0, false)
              OSX::CGReleaseDisplayFadeReservation(token)
            end
          end
        end
    
        def self.snap(token)
          display = OSX::CGMainDisplayID()
      
          if OSX::CGDisplayCapture(display) == OSX::KCGErrorSuccess
            begin
              ctx = OSX::CGDisplayGetDrawingContext(display)
              if ctx
                pic = OSX::CIImage.from('nikon.jpg')
            
                OSX::CGDisplayFade(token, 0.0, OSX::KCGDisplayBlendSolidColor, OSX::KCGDisplayBlendNormal, 0, 0, 0, true)
            
                display_width, display_height = OSX::CGDisplayPixelsWide(display), OSX::CGDisplayPixelsHigh(display)
                pic_width, pic_height = pic.extent.size.width, pic.extent.size.height
                position_x, position_y = (display_width - pic_width) / 2.0, (display_height - pic_height) / 2.0
            
                OSX::CGContextDrawImage(ctx, OSX::NSRectFromString("#{position_x} #{position_y} #{pic_width} #{pic_height}"), pic.cgimage)
            
                sleep(0.7)
            
                OSX::CGDisplayFade(token, 0.0, OSX::KCGDisplayBlendNormal, OSX::KCGDisplayBlendSolidColor, 0, 0, 0, true)
              end
            ensure
              OSX::CGDisplayRelease(display)
            end
          end
        end
    end

    Screen.capture.save('desktop.jpg')

### Summary

First we created a simple capture class that used the new CGWindow API in Mac OSX 10.5, then we built upon that adding a fade effect around the actual screen capture. Next we drew an image directly on the display in between the fade, to make it even more obvious that we were taking a screenshot.

There we have it, a really useful tool for capturing screenshots of your desktop programatically.

### Special Thanks!

1. Thanks [Lachlan](http://lachstock.com.au/) for the challenge mate! :)
2. Thanks [Pete](http://notahat.com/) for your help with the Cocoa desktop fade semantics.
3. Thanks [DSevilla](http://www.flickr.com/photos/dsevilla/249202834/) for the camera image used above.

