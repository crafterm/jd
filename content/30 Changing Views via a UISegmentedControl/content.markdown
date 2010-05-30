<div style="float:right; margin-left: 10px">
  <img src="/assets/2010/5/26/1-italy.png" width="180">
  <img src="/assets/2010/5/26/2-australia.png" width="180">
</div>

It's boutique, shiny and several apps that ship with the iPhone do it,
in this article I'll step through using a UISegmentedControl to toggle
between different subviews, each with their own layout, within a
UINavigationController.

To see an example of this use case, take a look at the Apple Calendar
app, along the bottom of the screen is a toolbar containing a
UISegmentedControl, with the segments *List*, *Day* and
*Month*. Tapping on any of these segments changes the view to a
completely new layout.

The AppStore app also implements this paradigm to an extent - take a look
at the *Top 25* tab, in the navigation title view there's a
UISegmentedControl with the segment labels *Top Free*, *Top Paid* and
*Top Grossing*.

The AppStore variant is a bit simpler and can actually be implemented
using a single UITableView and multiple
UITableViewDataSource/UITableViewDelegate objects, with the
UISegmentedControl switching between each of them and reloading the
table upon index changes.

In my case though, I needed to build the full Ferrari, and allow for
switching between views with completely different layouts. In addition,
it all had to work well within a navigation controller, with elements
within these views pushing onto the navigation stack.

### Solution

The solution was to create specialized view controllers for each style
of view, and programatically add/remove these views as subviews to a
managing view controller, in response to selected segment index
changes on the UISegmentedControl.

To do all this, one has to create an additional UIViewController
subclass that manages the UISegmentedControl changes, maintains a
collection of sub view controllers and adds/removes their views on
demand.

The advantage of this approach, is that it keeps the business logic
between each subview separate, and makes it easy to add additional
segments later as your application grows.

#### Interface

    @interface SegmentManagingViewController : UIViewController <UINavigationControllerDelegate> {
        UISegmentedControl    * segmentedControl;
        UIViewController      * activeViewController;
        NSArray               * segmentedViewControllers;
    }

    @property (nonatomic, retain, readonly) IBOutlet UISegmentedControl * segmentedControl;
    @property (nonatomic, retain, readonly) UIViewController            * activeViewController;
    @property (nonatomic, retain, readonly) NSArray                     * segmentedViewControllers;

    @end

Here we define a view controller subclass for managing the
presentation of multiple subviews. `segmentedControl` is
the UISegmentedControl, either created and assigned in code, or via a
Interface Builder. `activeViewController` represents the view controller currently
being presented, and `segmentedViewControllers` is an array of all
view controllers presentable via the segmented control.

I'll get to the `UINavigationControllerDelegate` protocol in just a minute..

#### Implementation

    @interface SegmentManagingViewController ()

    @property (nonatomic, retain, readwrite) IBOutlet UISegmentedControl * segmentedControl;
    @property (nonatomic, retain, readwrite) UIViewController            * activeViewController;
    @property (nonatomic, retain, readwrite) NSArray                     * segmentedViewControllers;

    - (void)didChangeSegmentControl:(UISegmentedControl *)control;
    - (NSArray *)segmentedViewControllerContent;

    @end

In an anonymous category we redefine the interface properties as
readwrite for local accessor/mutator methods, and define method
signatures for a callback from the segmented control, and a helper
method to create the view controllers representing each segment.

    @implementation SegmentManagingViewController

    @synthesize segmentedControl, activeViewController, segmentedViewControllers;

    - (void)viewDidLoad {
        [super viewDidLoad];

        self.segmentedViewControllers = [self segmentedViewControllerContent];

        NSArray * segmentTitles = [self.segmentedViewControllers arrayByPerformingSelector:@selector(title)];

        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTitles];
        self.segmentedControl.selectedSegmentIndex = 0;
        self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;

        [self.segmentedControl addTarget:self
                                  action:@selector(didChangeSegmentControl:)
                        forControlEvents:UIControlEventValueChanged];

        self.navigationItem.titleView = self.segmentedControl;
        [self.segmentedControl release];

        [self didChangeSegmentControl:self.segmentedControl]; // kick everything off
    }

    - (NSArray *)segmentedViewControllerContent {
        UIViewController * controller1 = [[ItalyViewController alloc] initWithParentViewController:self];
        UIViewController * controller2 = [[AustraliaViewController alloc] initWithParentViewController:self];

        NSArray * controllers = [NSArray arrayWithObjects:controller1, controller2, nil];

        [controller1 release];
        [controller2 release];

        return controllers;
    }

`viewDidLoad` creates our UISegmentedControl object within the
navigation controller title, and installs a target/action pair to call
back on `didChangeSegmentControl:` when the selected segment index
changes. It also calls upon `segmentedViewControllerContent` to return
an array containing the view controllers we'll be toggling between. In
this case, view controllers representing Italy (fantastic holiday a
few years back) and Australia, where I come from.

We'll also implement our memory management methods:

    - (void)didReceiveMemoryWarning {
        [super didReceiveMemoryWarning];

        for (UIViewController * viewController in self.segmentedViewControllers) {
            [viewController didReceiveMemoryWarning];
        }
    }

    - (void)viewDidUnload {
        self.segmentedControl         = nil;
        self.segmentedViewControllers = nil;
        self.activeViewController     = nil;

        [super viewDidUnload];
    }


Now onto the beef, when a segment index change occurs, the
UISegmentedControl will call back to our `didChangeSegmentControl:`
method, where we can interrogate the segmented control for the new
index.

When this changes we need to remove the current active subview
from the view hierarchy, and replace it with a new one according to
the users segmented control selection.

Since we're also manipulating the view hierarchy directly, we also
need to fire `viewWillDisappear:`/`viewDidDisappear:` and their
counterparts `viewWillAppear:`/`viewDidAppear:` appropriately as well to
ensure the outbound and inbound view controllers are notified of their
view's visual status change:

    - (void)didChangeSegmentControl:(UISegmentedControl *)control {
        if (self.activeViewController) {
            [self.activeViewController viewWillDisappear:NO];
            [self.activeViewController.view removeFromSuperview];
            [self.activeViewController viewDidDisappear:NO];
        }

        self.activeViewController = [self.segmentedViewControllers objectAtIndex:control.selectedSegmentIndex];

        [self.activeViewController viewWillAppear:NO];
        [self.view addSubview:self.activeViewController.view];
        [self.activeViewController viewDidAppear:NO];

        NSString * segmentTitle = [control titleForSegmentAtIndex:control.selectedSegmentIndex];
        self.navigationItem.backBarButtonItem  = [[UIBarButtonItem alloc] initWithTitle:segmentTitle style:UIBarButtonItemStylePlain target:nil action:nil];
    }

    @end

The final part extracts the title of the selected segment, and
creates a 'back' UIBarButtonItem with it's name matching that title. This
ensures that when we push onto the navigation stack from within one of
these subviews, the navigation item back button matches the name of
the selected segment.

We also pass on any view controller life cycle methods to the active subview:

    - (void)viewWillAppear:(BOOL)animated {
        [super viewWillAppear:animated];
        [self.activeViewController viewWillAppear:animated];
    }

    - (void)viewDidAppear:(BOOL)animated {
        [super viewDidAppear:animated];
        [self.activeViewController viewDidAppear:animated];
    }

    - (void)viewWillDisappear:(BOOL)animated {
        [super viewWillDisappear:animated];
        [self.activeViewController viewWillDisappear:animated];
    }

    - (void)viewDidDisappear:(BOOL)animated {
        [super viewDidDisappear:animated];
        [self.activeViewController viewDidDisappear:animated];
    }

#### Navigation Controllers

Interestingly, if we place this managing view controller within a
UINavigationController, the managing view controller won't actually receive
the `viewWillAppear:`/`viewDidAppear:` events from the system. To be
notified of when this occurs inside a navigation view hierarchy, we need to implement the
UINavigationControllerDelegate methods to be informed when a view has
been pushed on or off the navigation stack.

Without these methods bizarre side effects can occur, such as
UITableView's within a segments subview not knowing when to
appropriately de-highlight the selected row.

    - (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
        [viewController viewDidAppear:animated];
    }

    - (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
        [viewController viewWillAppear:animated];
    }

#### Pushing onto the navigation stack

The final piece is to allow pushing onto the navigation stack from
within one of the managed subviews.

Each subview's UIViewController has an implicit `navigationController`
property that you can use to send the `pushViewController:animated:`
message to add an additional view controller to the navigation hierarchy.

In our case though, since each subview's view controller has
been instantiated outside of the navigation hierarchy, their
navigationController reference will be `nil`.

The other observation is that we don't actually want to push onto the
navigation stack from within the subview - we want to push onto the
navigation stack from the managing view controller.

The solution to this, is to pass the managing view controller to the
subviews, to correctly allow pushing onto the navigation stack from
within the subview. There's several ways to do this, in the code
above, I've defined a custom view controller initializer that accepts
a managing view controller reference.

### Conclusion

What I particularly like about this approach is that it separates
the code and behaviour of each subview into separate view controllers,
and assembles them together in a neat and compact manner.

Separate view controllers follow Apple's *single screen full of
content per view controller paradigm*, and pushing onto the navigation
controller via the managing view controller yields a comfortable
user experience.

An example XCode project of all this in action is also
[available](http://github.com/crafterm/SegmentedControlExample) if you'd
like to step through the details, enjoy.

**Updated**

* Example uploaded to [github](http://github.com/crafterm/SegmentedControlExample)
* Added pass of `didReceiveMemoryWarning` thanks to Jonah Williams
