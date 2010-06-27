<div style="float:right; margin-left: 10px">
  <img src="/assets/2010/5/26/1-italy.png" width="180">
  <img src="/assets/2010/5/26/2-australia.png" width="180">
</div>

Recently I
[investigated](/2010/5/26/uisegmented-control-view-switching)
switching between multiple different views using a
`UISegmentedControl`, similar to iCal or the AppStore application.

#### Background

The best [approach](/2010/5/26/uisegmented-control-view-switching) I
could find to work at the time was to use a _managing_ view controller,
that enclosed an array of sub view controllers. The
`UISegmentedControl` would then switch between these sub views by
adding/removing the selected segment's view as a subview of the
managing controller's view.

While this worked and satisfied one of my main requirements of keeping
the logic between view controllers separate, there were a few things that
frustrated me about the approach:

* The enclosing view controller that managed the sub views was in
  effect a 'container' view controller, and I distinctly remembered
  Evan Doll's WWDC 2009 presentation where cautioned against building
  any style of container view controllers.

* To push onto the navigation stack from within a sub view, each
  sub view needed to have a reference back to the managing container
  view controller, either via a property and/or custom constructor, as
  the sub views weren't created within the navigation hierarchy and
  hence had a nil `navigationController` property.

* Since the managing view controller enclosed a series of sub view
  controllers, some in the view hierarchy and some not, view life
  cycle messages needed to be forwarded to the sub view controllers to
  be good UIKit citizens.

While attending WWDC 2010 just a few weeks ago, I managed to talk to
several UIKit engineers and together we managed to find a much better
approach to solving this UI paradigm without requiring a container
view controller.

### New Shiny

The new approach is to utilize a `UINavigationController` rather than a
managing view controller. However, rather than use the more common
navigation controller methods `pushViewController:animated:` and
`popViewControllerAnimated:`, we will manipulate the navigation view
hierarchy directly by modifying the `viewControllers` property using
the `setViewControllers:animated:` method.

The technique essentially works as follows. Any index change in the
designated `UISegmentedControl` calls upon a method in a custom
`NSObject` descendant controller object of ours. This controller accesses the
selected view controller appropriate for the selected segment and
installs it into the navigation controller stack directly using the
`setViewControllers:animated:` method.

Finally, since the navigation view hierarchy has been modified
directly, we then re-install the segmented control as the title view on the
incoming view controller so that further segment changes can be made.

I've reimplemented the
[previous](http://github.com/crafterm/SegmentedControlExample) example
application I built using the managing view controller with this new
pattern, let's step through it to demonstrate how it all works.

Since we'll be using standard `UINavigationController` and
`UISegmentedControl` objects in this application, I'll skip
straight to our custom controller object that accepts a message
indicating a change in selected segment index, and does the navigation
controller magic.

#### Interface

    :::objective-c
    @interface SegmentsController : NSObject {
        NSArray                * viewControllers;
        UINavigationController * navigationController;
    }

    @property (nonatomic, retain, readonly) NSArray                * viewControllers;
    @property (nonatomic, retain, readonly) UINavigationController * navigationController;

    - (id)initWithNavigationController:(UINavigationController *)aNavigationController
                       viewControllers:(NSArray *)viewControllers;

    - (void)indexDidChangeForSegmentedControl:(UISegmentedControl *)aSegmentedControl;

    @end

Here we define the `SegmentsController` interface to be an `NSObject`
descendant, with storage for the view controllers appropriate for each
segment, and a reference to our navigation controller.

A custom constructor accepts the view and navigation controller, and
the `indexDidChangeForSegmentedControl:` is our method that can
be invoked when a given segmented control index changes.

#### Implementation

    :::objective-c
    @interface SegmentsController ()
    @property (nonatomic, retain, readwrite) NSArray                * viewControllers;
    @property (nonatomic, retain, readwrite) UINavigationController * navigationController;
    @end

    @implementation SegmentsController

    @synthesize viewControllers, navigationController;

    - (id)initWithNavigationController:(UINavigationController *)aNavigationController
                       viewControllers:(NSArray *)theViewControllers {
        if (self = [super init]) {
            self.navigationController = aNavigationController;
            self.viewControllers = theViewControllers;
        }
        return self;
    }

    - (void)indexDidChangeForSegmentedControl:(UISegmentedControl *)aSegmentedControl {
        NSUInteger index = aSegmentedControl.selectedSegmentIndex;
        UIViewController * incomingViewController = [self.viewControllers objectAtIndex:index];

        NSArray * theViewControllers = [NSArray arrayWithObject:incomingViewController];
        [self.navigationController setViewControllers:theViewControllers animated:NO];

        incomingViewController.navigationItem.titleView = aSegmentedControl;
    }

    - (void)dealloc {
        [super dealloc];
        self.viewControllers = nil;
        self.navigationController = nil;
    }

    @end

In the anonymous category we redefine our properties read/write so we
can mutate them from within the implementation only, and define our
constructor to store references to our given view and navigation
controllers.

The meat of the work is done next. Our segmented control will be
appropriately configured to call upon
`indexDidChangeForSegmentedControl:` when it's segment index
changes. When this occurs, we retrieve the new index from the segmented
control, and the relevant view controller to install (a more complex
example could instantiate/cache view controllers to conserve memory),
and assign it to the navigation controller via the
`setViewControllers:animated:` message.

Once installed, we then apply the segmented control to the title view
of the view controller we just installed into the navigation
controller, and are done.

Finally, we implement appropriate memory management methods to
de-allocate resources when being released.

#### Application Delegate Implementation

    :::objective-c
    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

        NSArray * viewControllers = [self segmentViewControllers];

        UINavigationController * navigationController = [[[UINavigationController alloc] init] autorelease];
        self.segmentsController = [[SegmentsController alloc] initWithNavigationController:navigationController viewControllers:viewControllers];

        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[viewControllers arrayByPerformingSelector:@selector(title)]];
        self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;

        [self.segmentedControl addTarget:self.segmentsController
                                  action:@selector(indexDidChangeForSegmentedControl:)
                        forControlEvents:UIControlEventValueChanged];

        [self firstUserExperience];

        [window addSubview:navigationController.view];
        [window makeKeyAndVisible];

        return YES;
    }

In this example, I've instantiated and configured the segmented control,
navigation and segment controllers from within the application
delegate, but this could equally be done at a lower level depending on
your application.

In particular, the segmented control has its target/action pair set up to
point to our `indexDidChangeForSegmentedControl:` method described
above.

The `segmentViewControllers` methods returns the view controllers
relating to each segment (the `title` property of each view controller
is used as the segment's title via the NSArray
`arrayByPerformingSelector:` extension), and `firstUserExperience`
kicks everything off by selecting and installing the first segment.

    :::objective-c
    - (NSArray *)segmentViewControllers {
        UIViewController * italy     = [[ItalyViewController alloc] initWithNibName:@"ItalyViewController" bundle:nil];
        UIViewController * australia = [[AustraliaViewController alloc] initWithStyle:UITableViewStyleGrouped];

        NSArray * viewControllers = [NSArray arrayWithObjects:italy, australia, nil];
        [australia release]; [italy release];

        return viewControllers;
    }

    - (void)firstUserExperience {
        self.segmentedControl.selectedSegmentIndex = 0;
        [self.segmentsController indexDidChangeForSegmentedControl:self.segmentedControl];
    }

### Summary

Using a `UINavigationController` based approach has several distinct
advantages that I quite like - it doesn't require a container
controller, and hence no custom code for handling memory, rotation, or
view life cycle events.

Code-wise it's much smaller than the previous implementation, and will
be a lot easier to maintain. Segment view controllers can push
directly onto the navigation controller stack since they're set within the
navigation hierarchy, and no special management of parent view
controllers is required.

The full [XCode](http://github.com/crafterm/SegmentedControlRevisited)
project of the example above is available if you'd like to examine it
further. Enjoy.

