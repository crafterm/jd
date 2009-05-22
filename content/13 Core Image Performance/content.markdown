<img src="/assets/2007/12/16/IMG_2990.jpg"/>

Following my [previous](/2007/12/12/attachment-fu-with-core-image) post, a few people have asked me how well Core Image performs in comparison to [RMagick](http://rmagick.rubyforge.org/) and [ImageScience](http://seattlerb.rubyforge.org/ImageScience.html) when used as part of Attachment Fu. To answer these questions, I've spent a bit of time collecting some performance results.

Please note that as with all performance testing, results will vary according to many parameters such as hardware, processing power, and even the input image content itself, as you'll see below.

Naturally Core Image *should* be faster since it will run hardware accelerated on my MacBook Pro, so please take these results more as an indication of library characteristics rather than final timings. The tests I performed also mirrored how each library was being invoked by Attachment Fu, and beyond performance there's also several other tangible benefits to Core Image such as deployment and access via RubyCocoa to keep in mind as well.

The first test performs 5 successive resizes of a 1mb image under each library. The input image is a complex photo (smaller version above) taken in Berlin of parts of the Berlin Wall, including a high colour range and lots of shapes and sizes:

<img src="/assets/2007/12/16/complex-1mb-image-resize-average.jpg"/>

Both RMagick and ImageScience yield consistent results as expected. Core Image's resize values are interesting as successive resizes are twice as fast than the first, which I speculate would include an initial Core Image to OpenGL compilation phase of the resize operation being performed.

Similar characteristics can be observed with a slightly larger image size of around 2.5mb:

<img src="/assets/2007/12/16/complex-2.5mb-image-resize-average.jpg"/>

In both cases, Core Image performs really well, particularly on consecutive runs.

The actual image content being resized also affects results as well - the following test uses a blank image of identical dimensions to the 2.5mb Berlin image:

<img src="/assets/2007/12/16/blank-image-resize-average.jpg"/>

Finally, the following graph shows the results of resizing 6 versions of the Berlin image with each library, at increasing size & dimensions. The results plotted for each measurement are calculated over the average of 5 resizes of each image.

<img src="/assets/2007/12/16/increasing-sizes-average.jpg"/>

At small image sizes, we can see the difference in resize time to be essentially negligible, however as image size increase up to 500kb, the hardware acceleration of Core Image starts to shine, particularly around the 2.5mb - 5mb range and beyond.

There does seem to be a limit to performance gains, on Friday [Ben](http://germanforblack.com/) and I also made a few experiments with really large image sizes (TIFF files around 90mb), and noticed that Core Image can be slower than Image Science under these conditions:

<img src="/assets/2007/12/16/90mb-image-resize-average.jpg"/>

At this stage I can only speculate as to why this occurs, and it deserves further inspection.

Another interesting aspect to look at is the actual on disk size of the resized images. The following is a directory listing of the results after the 2.5mb image (2200x1467 resize to 640x480):

    -rw-r--r--  1 crafterm  staff  153492 16 Dec 22:30 core_image-complex_resized.jpg
    -rw-r--r--  1 crafterm  staff  288455 16 Dec 22:30 image_science-complex_resized.jpg
    -rw-r--r--  1 crafterm  staff  356827 16 Dec 22:30 rmagick-complex_resized.jpg

Core Image's default compression range is quite impressive, and while I'm sure the other libraries compression factors can be fine tuned I suspect it would also affect their relative performance measurements.

All measurements shown in the graphs are in seconds, and the test machine was my MacBook Pro, 15" Intel Core 2 Duo, 2.16 Ghz with an ATI Radeon X1600 video card with 128mb vram. I'd certainly be keen to see how other types of hardware perform, so please feel free to run the test code on your system and send me the resultant graphs, and I'll add them to the project.

All test code and input images (except for the 90mb example) are available in a git repository [online](http://git.redartisan.com/?p=af_ci_extras.git;a=tree).

