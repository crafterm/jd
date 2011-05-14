<div style="float:right; margin-left: 10px">
  <img src="/assets/2011/5/13/1-icon-screenshot.png" width="280px">
</div>

In this post I discuss several points regarding a port of an AppKit
based NSView drawRect implementation under iOS with Core Graphics.

IconApp is an example app written by my friend [Matt
 Gallagher](http://cocoawithlove.com/)
 as part of an excellent
 [blog post](http://cocoawithlove.com/2011/01/advanced-drawing-using-appkit.html)
demonstrating some advanced drawing techniques on the Mac using AppKit classes such as [NSBezierPath](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/ApplicationKit/Classes/NSBezierPath_Class/Reference/Reference.html) and
[NSGradient](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/ApplicationKit/Classes/NSBezierPath_Class/Reference/Reference.html), etc.

The shape drawn is a detailed icon, with complex radial and linear
gradients, providing a blue background over a floral heart unicode
character. A final piece of polish places a further gradient over the
top of the character to give it a nice reflection similar to icons
found in the dock, or on iOS.

Matt's post discusses the actual construction of the icon and how breaking
the draw down into various layers helps build a complex image out of
smaller simpler constructs.

With iOS having an equivelent UIBezierPath class but an absence of
NSGradient, I decided to scratch the itch of porting the drawing code
to iOS, but at a deeper level with Core Graphics directly.

The code for the iOS version is available on
 [GitHub](https://github.com/crafterm/IconApp)
 if you're interested in taking a look.

Generally speaking the code translated across to Core Graphics quite
easily, and I could almost see the underlying Core Graphics calls used to
implement the higher level AppKit classes. It was also much easier to
write the core graphics code having a pre-designed target shape with
all the colours, offsets, etc, available.

A few noticeable areas of difference:

### C API

The obvious one - Core Graphics is a C API rather than
AppKit's Objective-C API, and works with the current graphics context
directly as the first parameter to almost all method calls.

### AppKit & Core Graphics Gradients

NSGradient draws a radial gradient when sent
*drawInRect:relativeCenterPosition:* and a linear gradient when sent
*drawInBezierPath:angle:*. Core Graphics splits these two operations
into separate *CGContextDrawLinearGradient* and
*CGContextDrawRadialGradient* methods but the parameters you provide
differ. eg:

#### Core Graphics

    :::objective-c
    void CGContextDrawLinearGradient(
       CGContextRef context,
       CGGradientRef gradient,
       CGPoint startPoint,
       CGPoint endPoint,
       CGGradientDrawingOptions options
    );

#### AppKit NSGradient class

    :::objective-c
    - (void)drawInRect:(NSRect)rect angle:(CGFloat)angle

I found it useful, particularly with the non-rectangular vertical
linear gloss gradient to use *CGContextGetClipBoundingBox* to obtain a
CGRect containing the clipping area, and hence ease finding the
highest and lowest point of the path to use as the start and end point.

### Colours

You can use *UIColor* to obtain a *CGColorRef* value, however a
number of the CGContext* methods also accept ColorComponent values,
eg:

    CGGradientRef CGGradientCreateWithColors(
       CGColorSpaceRef space,
       CFArrayRef colors,
       const CGFloat locations[]
    );

    CGGradientRef CGGradientCreateWithColorComponents(
       CGColorSpaceRef space,
       const CGFloat components[],
       const CGFloat locations[],
       size_t count
    );

*components* is an array of float values dependent on the colour space
 in use, eg. in the case of device gray colourspace where colours are
 defined as a white value and alpha, *components* is an array of
 pairs:

    colourspace = CGColorSpaceCreateDeviceGray();
    CGFloat glossLocations[]  = { 0.0, 0.5, 1.0 };
    CGFloat glossComponents[] = { 1.0, 0.85, 1.0, 0.50, 1.0, 0.05 };
    gradient = CGGradientCreateWithColorComponents(colourspace, glossComponents, glossLocations, 3);

but in the case of RGB colourspace where 4 numbers are required (red,
green, blue and alpha), *components* expects an array of quads:

    colourspace = CGColorSpaceCreateDeviceRGB();
    CGFloat tComponents[] = { 0.0, 0.68, 1.00, 0.75,
                              0.0, 0.45, 0.62, 0.55,
                              0.0, 0.45, 0.62, 0.00 };
    CGFloat tGlocations[] = { 0.0, 0.25, 0.40 };
    gradient = CGGradientCreateWithColorComponents(colourspace, tComponents, tGlocations, 3);

The number of pairs, quads, etc, is specified by the last parameter
identifying the location offsets for each gradient colour.

### Drawing Text

Core Graphics can draw text to the screen with *CGContextShowText*
and friends, however by default it expects MacRoman is the encoding
unless you change the font type and then use Core Text or similar to
convert string characters to glyphs. For the moment I've used NSString
*drawAtPoint:WithFont* but will be adventuring down the Core Text path
soon.

### Summary

Complex constructs can certainly be drawn using Core Graphics, and by
breaking each part of the final image down into layers paths, fills,
gradients, strokes, etc, you can build up quite intruiging and
interesting graphics.

AppKit has some advanced Objective-C API's for drawing, but you can
certainly achieve similar results by delving into Core Graphics under iOS.

If you're interested in the details the code for the full project is
available up on [GitHub](https://github.com/crafterm/IconApp). Thanks again to Matt for an inspiring [blog post]([blog](http://cocoawithlove.com/2011/01/advanced-drawing-using-appkit.html), and with some help
understanding the final gloss gradient!
