<div style="float:right; margin-left: 10px; padding-right:15px">
<img src="/assets/2010/6/6/stage-1.png" width="450" style="padding: 5px"/>
<br/>
<img src="/assets/2010/6/6/stage-10-landscape.png" width="450" style="padding: 5px"/>
</div>

The iPad has ushered in a suite of new awesome user interface
paradigms with it's large screen and enhanced performance.

In this article, I'll step through using one of the new user interface
elements in iPhone SDK 3.2+, the `UISplitViewController`, in particular
managing multiple views with their own navigation controller stack,
handling all orientations.

#### Concept

Since I'm an avid cyclist and the Giro d'Italia just finished, in this
article's we'll step through an example application that lists the
name and distance of each stage.

When tapped, we'll show a photo from Melbourne's most popular cycling
blog, [Cycling Tips](http://www.cyclingtipsblog.com/), and allow the
user to tap through to the Cycling Tips article summarizing the stage
(full credits to Cycling Tips, they've done an awesome job at covering
the Giro this year).

I'll use landscape orientation terminology to describe the visual
aspects of the split view controller in this article, but please
assume normal split view controller semantics with the left hand side
of the split view appearing in a popup view when in portrait
mode. We'll discuss the code required to get this to work as well.

#### Model

Since we want to focus on the `UISplitViewController`, I'll browse
over the data model for this particular application since it is quite
small, all the code is
[available](http://github.com/crafterm/SplitViewExample) online, and
it's just a single Core Data *Stage* entity containing attributes
relevant to each stage.

I definitely recommend utilizing Core Data for your models where
possible, I find it fast and easy to use, and its great for
prototyping new ideas.

For data persistence it's awesome, you can switch between using
in-memory storage and SQLlite during the development making it easy to
always have fresh content while you're making changes.

### Table view list of Stages

On to the controller code, along the left hand side of the split view controller,
we'll show a table view, with each stage of the Giro being listed in
a separate cell.

#### StageTableViewController Interface

    :::objective-c
    @interface StageTableViewController : UITableViewController {
        NSFetchedResultsController * stageResultsController;

        NSMutableDictionary        * stageViewControllers;

        UIPopoverController        * popoverController;
        UIBarButtonItem            * popoverButtonItem;
    }

    @property (nonatomic, retain) NSFetchedResultsController * stageResultsController;

    @property (nonatomic, retain) NSMutableDictionary        * stageViewControllers;

    @property (nonatomic, retain) UIPopoverController        * popoverController;
    @property (nonatomic, retain) UIBarButtonItem            * popoverButtonItem;

    - (void)autoselectFirstStage;

    @end

    @protocol PopupManagingViewController
    - (void)showPopoverButtonItem:(UIBarButtonItem *)barButtonItem;
    - (void)invalidatePopoverButtonItem:(UIBarButtonItem *)barButtonItem;
    @end

The `stageResultsController` property provides access to our Core Data backed
model.

In addition to this we define storage for the known view controllers
we present on the right hand side of the split view controller. This
effectively caches view controllers we've already shown, so if the user taps back to
them, they show instantly rather than re-fetch data.

We also define an `autoselectFirstStage` method that the application
delegate can use to automatically select and show the first stage upon
startup.

When orientated to portrait, the left hand side of the split view controller
disappears and becomes available via a popup. The `popoverController`
property is responsible for showing the view controller inside a popover
view when a user taps the `popoverButtonItem` button.

We also define a protocol our detail view controller can implement to
install and remove the button allowing access to the popover when we
switch between detail views in portrait mode.

#### StageTableViewController Implementation

    :::objective-c
    @implementation StageTableViewController

    @synthesize stageResultsController, stageViewControllers, popoverButtonItem, popoverController;

    - (void)viewDidLoad {
        [super viewDidLoad];

        self.title = @"Stages";
        self.stageResultsController = [[ContentController sharedInstance] stageResultsController];

        NSUInteger stageCount = [self tableView:self.tableView numberOfRowsInSection:0];
        self.contentSizeForViewInPopover = CGSizeMake(320.0, self.tableView.rowHeight * stageCount);
        self.clearsSelectionOnViewWillAppear = NO;

        self.stageViewControllers = [NSMutableDictionary dictionary];
    }

    - (void)autoselectFirstStage {
        NSIndexPath * startPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:startPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:startPath];
    }

In `viewDidLoad`, we configure the view controller and create
references to our model layer's `NSFetchedResultsController`. Our
`autoselectFirstStage` method ensures the table view and delegate are
informed of our selection.

    :::objective-c
    - (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
        return [[self.stageResultsController sections] count];
    }

    - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.stageResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }

    - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

        static NSString *CellIdentifier = @"StageCell";

        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        }

        Stage * stage = [self.stageResultsController objectAtIndexPath:indexPath];
        cell.textLabel.text = stage.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Stage %@ 148 kms", stage.index];

        return cell;
    }

We then implement the required `UITableViewDataSource` protocol methods
to return our content to fill the table view when requested.

For some extra shine, we would also want to implement a custom
`UITableViewCell` as well to nicely show all the stage content. I'll
follow this up in a subsequent article.

    :::objective-c
    - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        Stage * stage = [self.stageResultsController objectAtIndexPath:indexPath];

        // invalidate the current popover button if one is being used
        UINavigationController * currentStageNavigationController = self.splitViewController.rightSideViewController;
        UIViewController<PopupManagingViewController> * currentViewController = [currentStageNavigationController rootViewController];
        [currentViewController invalidatePopoverButtonItem:self.popoverButtonItem];

        // install the new viewcontrollers array (LHS: stage view controller, RHS: incoming detail navigation controller)
        UINavigationController * stageNavigationController = [self.stageViewControllers valueForKey:stage.name];

        if (!stageNavigationController) {
            StageDetailViewController * detailViewController = [[StageDetailViewController alloc] initWithStage:stage];
            stageNavigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
            [detailViewController release];
            [self.stageViewControllers setValue:stageNavigationController forKey:stage.name];
            [stageNavigationController release];
        }

        self.splitViewController.viewControllers = [NSArray arrayWithObjects:self.navigationController, stageNavigationController, nil];

        // dismiss the popover if present, and add the popover button to the incoming detail view controller
        [self.popoverController dismissPopoverAnimated:YES];

        if (self.popoverButtonItem) {
            UIViewController<PopupManagingViewController> * viewController = [stageNavigationController rootViewController];
            [viewController showPopoverButtonItem:self.popoverButtonItem];
        }
    }

The only `UITableViewDelegate` method we'll implement is
`tableView:didSelectRowAtIndexPath:` for when a user taps a particular
stage in the table view.

In `tableView:didSelectRowAtIndexPath:` we perform a few
tasks. Essentially, we want to create a `StageDetailViewController`
instance within a navigation controller, and cache it in case the user
selects this table row again.

Once we've created (or retrieved a cached version of) our
`StageDetailViewController` we reassign the `viewControllers` property
on the split controller, specifying the new left/right hand side view
controllers to be shown.

In this case, we never want the left hand side to change from being
the table view of all stages, so position 0 in the returned array
is the `navigationController` reference of the `StageTableViewController`
(be careful to remember this in your apps as you'll get some funny
behaviour if you return the view controller directly).

Position 1 of the array includes the newly created stage detail view
controller, inset within a `UINavigationController` instance.

Once the 'viewController' property has been assigned, the split view
updates instantly to show our selected view controller in the right
hand side of the split view.

In addition to this, if the user selected an item in the table while
in portrait mode from a popover, we dismiss the popover view, and
install a new popover button in the detail view that the user can tap
if they wish to select another item.

Finally as good memory management citizens we also implement
`viewDidUnload` and `didReceiveMemoryWarning` to release allocated
and cached resources respectively.

    :::objective-c
    - (void)viewDidUnload {
        [super viewDidUnload];
        self.stageViewControllers   = nil;
        self.popoverButtonItem      = nil;
        self.popoverController      = nil;
        self.stageResultsController = nil;
    }

    - (void)didReceiveMemoryWarning {
      [super didReceiveMemoryWarning];
      [self.stageViewControllers removeAllObjects];
    }

The full [XCode](http://github.com/crafterm/SplitViewExample) project
also includes the `UISplitViewController` delegate code to
install/remove the popover button when the user changes orientation.

Now that we've implemented the left hand side of the split view, let's
move onto the right hand side detail view.

#### StageDetailViewController interface

The right hand side of the split view controller will initially show a
picture from the selected Giro racing stage. We'll also place this
image inside a scroll view so the user can pan and zoom in/out, etc.

We will also install a button within the navigation bar so the user
can drill down to the blog post summarizing that stage.

Here's the interface:

    :::objective-c
    @interface StageDetailViewController : UIViewController <ImageLoaderDelegate, UIScrollViewDelegate, PopupManagingViewController> {
        Stage                   * stage;

        UIScrollView            * scrollView;
        UIActivityIndicatorView * activityView;

        UIImageView             * stageImageView;
        ImageLoader             * imageLoader;
    }

    @property (nonatomic, retain) Stage                            * stage;

    @property (nonatomic, retain) IBOutlet UIScrollView            * scrollView;
    @property (nonatomic, retain) IBOutlet UIActivityIndicatorView * activityView;

    @property (nonatomic, retain) IBOutlet UIImageView             * stageImageView;
    @property (nonatomic, retain) ImageLoader                      * imageLoader;

    - (id)initWithStage:(Stage *)stage;

    @end

The `ImageLoader` property is a helper class I've written for asynchronously
downloading images over the network, utilizing the excellent
[ASIHttpRequest](http://allseeing-i.com/ASIHTTPRequest/) library.

#### StageDetailViewController implementation

    :::objective-c
    @interface StageDetailViewController ()
    - (void)didSelectReadArticle:(id)sender;
    @end

    @implementation StageDetailViewController

    @synthesize stage, stageImageView, imageLoader, activityView, scrollView;

    - (id)initWithStage:(Stage *)aStage {
        if (self = [super initWithNibName:@"StageDetailViewController" bundle:nil]) {
            self.stage = aStage;
        }
        return self;
    }

    - (void)viewDidLoad {
        [super viewDidLoad];

        self.title = [NSString stringWithFormat:@"Giro d'Italia: %@", self.stage.name];

        self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];

        self.scrollView.maximumZoomScale = 5.0f;
        self.scrollView.minimumZoomScale = 1.0f;
        self.scrollView.delegate = self;

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Read Article" style:UIBarButtonItemStylePlain target:self action:@selector(didSelectReadArticle:)];
        self.navigationItem.backBarButtonItem  = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Stage %@", self.stage.index] style:UIBarButtonItemStylePlain target:nil action:nil];

        self.imageLoader = [[ImageLoader alloc] initWithURL:self.stage.imageURL];
        self.imageLoader.delegate = self;
        [self.imageLoader start];
    }

    - (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
        return self.stageImageView;
    }

In the anonymous category we define a `didSelectReadArticle:` method
to be invoked when the taps the button to drill down to read the full
blog post summarizing the race stage.

In `viewDidLoad`, we configure the view's title and background colour
(`scrollViewTexturedBackgroundColor` looks just awesome on the iPad),
the scroll view's scale and delegate properties, install a 'Read
Article' button on the right hand side of the navigation bar, and
redefine the *back* button to be the stage number rather than the full
stage name.

Finally, we create an `ImageLoader` instance and start retrieving an
image of the specified stage.

Should a user tap the 'Read Article' button the following method is called:

    :::objective-c
    - (void)didSelectReadArticle:(id)sender {
        StageArticleViewController * articleViewController = [[StageArticleViewController alloc] initWithStage:self.stage];
        [self.navigationController pushViewController:articleViewController animated:YES];
        [articleViewController release];
    }

This will push an instance of `StageArticleViewController` onto the
navigation stack, which includes a web view configured to load the
race stage summary.

Once again we ensure all allocated resources are released when the
view is deconstructed.

    :::objective-c
    - (void)viewDidUnload {
        [super viewDidUnload];
        self.stageImageView       = nil;
        self.imageLoader.delegate = nil;
        self.imageLoader          = nil;
        self.scrollView           = nil;
    }

    - (void)dealloc {
        [super dealloc];
        self.stage = nil;
    }

<img src="/assets/2010/6/6/stage-10-portrait.png" width="350" style="float:right; padding: 10px; padding-right: 20px"/>

Here we split deallocation of the view related items from the stage,
since the stage was specified in the constructor whereas
`stageImageView`, `scrollView` and the `imageLoader` objects were
created in `viewDidLoad`.

####  Summary

As we can see, `UISplitViewController` is really useful for
master-detail style interfaces and it's configured similarly to a
`UITabBarController` by assigning it's `viewControllers` property.

I've skipped over a few parts of the example app to keep the post
length under control, such as implementation of the
`StageArticleViewController`, orientation permissions on all our view
controllers, the image loader callbacks to add the image to the scroll
view upon completion of download, etc. All of this is availablae in
the full [XCode](http://github.com/crafterm/SplitViewExample) project
however, please feel free to peruse the code online.


