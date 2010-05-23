<img src="/assets/2010/5/23/3-simulator.png" width="180" style="float:right">

Just about every iPhone/iPad application needs them, scrollable views
to let your users pan and/or zoom over more content than can be shown
on one screen at a time.

There's several approaches out there for making your content
scrollable with a UIScrollView, some of them quite complex with
overlapping views in Interface Builder, others recommending heavy use
of code for layout.

The method I've found the quite effective of late in terms of code and
ease of design in Interface Builder, is to add a UIScrollView to
your UIViewController subclass' UIView, and create a separate UIView
in your XIB, where the underlying full content can be added. Upon
viewDidLoad, you can add this UIView to the UIScrollView's subview
property, and set the contentSize and zoom properties appropriately.

Here's the steps:

### Add UIScrollView to your UIViewController subclass' UIView

#### Code

Define the scroll view in your class interface and synthesize the property in the
implementation.

    @interface MyViewController : UIViewController {
        UIScrollView * scrollView;
    }

    @property (nonatomic, retain) IBOutlet UIScrollView * scrollView;

    @end

#### Interface Builder

Add the UIScrollView to your XIB, connecting it to your view
controller via the outlet. The UIScrollView can be placed within any
other decorations on the view such as navigation bars, tool/tab bars.

<img src="/assets/2010/5/23/1-add-scrollview.png">

### Create a separate UIView for your full content

Add an additional property for the view that will hold the content to
be added to the scroll view.

#### Code

    @interface MyViewController : UIViewController {
        UIScrollView * scrollView;
        UIView       * contentView;
    }

    @property (nonatomic, retain) IBOutlet UIScrollView * scrollView;
    @property (nonatomic, retain) IBOutlet UIView       * contentView;

    @end

#### Interface Builder

Create the view in interface builder, and connect it your contentView
outlet. This view doesn't have to be within standard iPhone view
dimensions, it can be of any size, since the scroll view will allow us
to pan over it. Add all the content you wish the user to be able to
pan over to this view.

<img src="/assets/2010/5/23/2-add-content-view.png">

### Configure the UIScrollView to pan over your content

Add the contentView as a sub view of the scroll view, and set the
contentSize property on the scroll view to be the bounds of the
content view, or if you have any dynamic text/etc, calculate the
height appropriately.

#### Code

    @synthesize scrollView, contentView, coverImage1;

    - (void)viewDidLoad {
        [super viewDidLoad];

        // set the scrollview content and configure appropriately
        [self.scrollView addSubview:self.contentView];
        self.scrollView.contentSize = self.contentView.bounds.size;
    }

Additionally, if you'd like pinch zooming, you can set the
maximumZoomScale/minimumZoomScale properties, and
viewForZoomingInScrollView: in your view controller as the
UIScrollView delegate.

### Summary

I find this pattern useful for several reasons, mainly that it keeps the
design and dimensions of content view separate from view that contains
the UIScrollView, and there's less complexity within the XIB.

It doesn't force any Interface Builder pain with overlapping
views or magic code to add scrolling to an existing view, and works
well when you'd like to retrofit a UIScrollView into an existing XIB
content.

The XCode project used to build this article and screenshots, etc, is also
[available](/assets/2010/5/23/ScrollViewExample.zip).
