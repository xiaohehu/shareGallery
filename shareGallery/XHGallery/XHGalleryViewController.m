//
//  XHGalleryViewController.m
//  XHGallery
//
//  Created by Xiaohe Hu on 12/24/14.
//  Copyright (c) 2014 Neoscape. All rights reserved.
//

#import "XHGalleryViewController.h"
#import "embModelController.h"
#import "FGalleryPhotoView.h"

#define kThumbnailSize 75
#define kThumbnailSpacing 4
static float        kTopViewHeight      = 45.0;
static float        kBottomViewHeight   = 45.0;

@interface XHGalleryViewController ()<UIPageViewControllerDelegate, FGalleryPhotoViewDelegate>
{
    int             itemsNum;
    float           view_width;
    float           view_height;
    NSTimer         *tapTimer;
    BOOL            _isThumbViewShowing;
    NSMutableArray  *_photoThumbnailViews;
    
    NSMutableArray  *arr_captions;
    NSMutableArray  *arr_images;
    NSMutableArray  *arr_fileType;
}

//Top View
@property (nonatomic, strong)           UIView                  *uiv_topView;
@property (nonatomic, strong)           UILabel                 *uil_numLabel;
@property (nonatomic, strong)           UIButton                *uib_back;
@property (nonatomic, strong)           UIButton                *uib_thumbView;
// Bottom View
@property (nonatomic, strong)           UIView                  *uiv_bottomView;
@property (nonatomic, strong)           UILabel                 *uil_caption;
// Page View
@property (nonatomic, readwrite)        NSInteger               currentPage;
@property (readonly, strong, nonatomic) embModelController		*modelController;
@property (strong, nonatomic)           UIPageViewController	*pageViewController;
// thumbs view
@property (nonatomic, strong)           UIScrollView            *thumbsView;
// play button
@property (nonatomic, strong)           UIImageView             *uiiv_playMovie;
@end

@implementation XHGalleryViewController

@synthesize modelController = _modelController;
@synthesize delegate;
@synthesize showCaption, showNavBar, startWithThumbView;
@synthesize arr_rawData;
@synthesize startIndex;

- (id)init
{
    if (self == [super init]) {
        showNavBar = YES;
        showCaption = YES;
        
        self.view.backgroundColor = [UIColor clearColor];
        _modelController = [[embModelController alloc] init];
        _photoThumbnailViews = [[NSMutableArray alloc] init];
        [self addGestureToView];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    // Prepare data
    [self prepareData];
    // Get current view's size
    view_height = self.view.frame.size.height;
    view_width = self.view.frame.size.width;
    
    // Get images
    
    
    // Init model controller
    _modelController = [[embModelController alloc] initWithImage:arr_images];
    
    // Init thumbs view
    _thumbsView = [[UIScrollView alloc]initWithFrame:self.view.frame];
    int numOfCellEachLine = view_width / (kThumbnailSize + kThumbnailSpacing);
    float blankSapce = (view_width - (kThumbnailSpacing + kThumbnailSize)*numOfCellEachLine + kThumbnailSpacing)/2;
    _thumbsView.contentInset = UIEdgeInsetsMake( kThumbnailSpacing, blankSapce, kThumbnailSpacing, kThumbnailSpacing);
    [self initPageView:startIndex];
    _currentPage = startIndex;
    
    // Check and load top & bottom views
    if (showCaption) {
        [self createBottomView];
    }
    if (showNavBar) {
        [self createTopView];
    }
    
    //Check the thumb view should load at first
    [self setUpThumbsView];
    if (startWithThumbView) {
        [self loadThumbsView:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

//----------------------------------------------------
#pragma mark - Prepare data
//----------------------------------------------------
- (void)prepareData
{
    arr_images = [[NSMutableArray alloc] init];
    arr_captions = [[NSMutableArray alloc] init];
    arr_fileType = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dict_tmp in arr_rawData) {
        [arr_images addObject: [dict_tmp objectForKey:@"file"]];
        [arr_captions addObject: [dict_tmp objectForKey:@"caption"]];
        [arr_fileType addObject: [dict_tmp objectForKey:@"type"]];
    }
    itemsNum = arr_images.count;
}

//----------------------------------------------------
#pragma mark - Set Up top view
//----------------------------------------------------
- (void)createTopView
{
    _uiv_topView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, view_width, kTopViewHeight)];
    _uiv_topView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    [self.view addSubview: _uiv_topView];
    
    float labelWidth = 100; // With for top view's buttons and label
    float fontSize = 15.0;
    _uil_numLabel = [[UILabel alloc] initWithFrame:CGRectMake((view_width-labelWidth)/2, 0, labelWidth, kTopViewHeight)];
    _uil_numLabel.text = [NSString stringWithFormat:@"%i of %i", (int)_currentPage+1, itemsNum];
    _uil_numLabel.textColor = [UIColor blackColor];
    [_uil_numLabel setFont:[UIFont boldSystemFontOfSize:fontSize]];
    _uil_numLabel.textAlignment = NSTextAlignmentCenter;
    _uil_numLabel.backgroundColor = [UIColor clearColor];
    [_uiv_topView addSubview: _uil_numLabel];
    
    _uib_back = [UIButton buttonWithType:UIButtonTypeCustom];
    _uib_back.frame = CGRectMake(0.0, 0.0, labelWidth, kTopViewHeight);
    _uib_back.backgroundColor = [UIColor clearColor];
    [_uib_back setTitle:@"﹤ BACK" forState:UIControlStateNormal];
    [_uib_back setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [_uib_back setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_uib_back.titleLabel setFont:[UIFont boldSystemFontOfSize:fontSize]];
    [_uiv_topView addSubview: _uib_back];
    [_uib_back addTarget:self action:@selector(tapBackButton:) forControlEvents:UIControlEventTouchUpInside];
    
    _uib_thumbView = [UIButton buttonWithType:UIButtonTypeCustom];
    _uib_thumbView.frame = CGRectMake(view_width - labelWidth, 0.0, labelWidth, kTopViewHeight);
    _uib_thumbView.backgroundColor = [UIColor clearColor];
    [_uib_thumbView setTitle:@"SEE ALL" forState:UIControlStateNormal];
    [_uib_thumbView setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [_uib_thumbView setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_uib_thumbView.titleLabel setFont:[UIFont boldSystemFontOfSize:fontSize]];
    [_uib_thumbView addTarget:self action:@selector(loadThumbsView:) forControlEvents:UIControlEventTouchUpInside];
    [_uiv_topView addSubview: _uib_thumbView];
}

//----------------------------------------------------
#pragma mark Delegate for Back button
//----------------------------------------------------
- (void)tapBackButton:(id)sender
{
    [self.delegate didRemoveFromSuperView];
}

//----------------------------------------------------
#pragma mark  Set up thumbs view
//----------------------------------------------------

-(void)setUpThumbsView
{
    _thumbsView.backgroundColor = [UIColor whiteColor];
    _thumbsView.hidden = YES;
    if (showNavBar){
        [self.view insertSubview:_thumbsView belowSubview:_uiv_topView];
    }
    else
        [self.view addSubview:_thumbsView];
    // create the thumbnail views
    [self buildThumbsViewPhotos];
}
//----------------------------------------------------```
#pragma mark Load thumbs view
//----------------------------------------------------
-(void)loadThumbsView:(id)sender
{
    [self removePlayButton];
    
    if (_isThumbViewShowing) {
        [self hideThumbnailViewWithAnimation:YES];
    }
    else {
        [self showThumbnailViewWithAnimation:YES];
    }
}

- (void)showThumbnailViewWithAnimation:(BOOL)animation
{
    _isThumbViewShowing = YES;
    
    [self layoutThumbs];
    [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Close", @"")];
    [_uib_thumbView setTitle:@"Close" forState:UIControlStateNormal];
    if (animation) {
        // do curl animation
        [UIView beginAnimations:@"uncurl" context:nil];
        [UIView setAnimationDuration:.666];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:_thumbsView cache:YES];
        [_thumbsView setHidden:NO];
        [UIView commitAnimations];
    }
    else {
        [_thumbsView setHidden:NO];
    }
}


- (void)hideThumbnailViewWithAnimation:(BOOL)animation
{
    _isThumbViewShowing = NO;
    [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"See all", @"")];
    [_uib_thumbView setTitle:@"See All" forState:UIControlStateNormal];
    if (animation) {
        // do curl animation
        [UIView beginAnimations:@"curl" context:nil];
        [UIView setAnimationDuration:.666];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:_thumbsView cache:YES];
        [_thumbsView setHidden:YES];
        [UIView commitAnimations];
    }
    else {
        [_thumbsView setHidden:NO];
    }
}

// creates all the image views for this gallery
- (void)buildThumbsViewPhotos
{
    NSUInteger i, count = itemsNum;
    for (i = 0; i < count; i++) {
        
        FGalleryPhotoView *thumbView = [[FGalleryPhotoView alloc] initWithFrame:CGRectZero target:self action:@selector(handleThumbClick:)];
        [thumbView setContentMode:UIViewContentModeScaleAspectFill];
        [thumbView setClipsToBounds:YES];
        [thumbView setTag:i];
        UIImage *rawImage = [UIImage imageNamed:arr_images[i]];
        UIGraphicsBeginImageContext(CGSizeMake(kThumbnailSize,kThumbnailSize));
        [rawImage drawInRect: CGRectMake(0, 0, kThumbnailSize, kThumbnailSize)];
        UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        thumbView.imageView.image = smallImage;
        [_thumbsView addSubview:thumbView];
        [_photoThumbnailViews addObject:thumbView];
    }
}

- (void)layoutThumbs
{
    float dx = 0.0;
    float dy = 49.0;
    // loop through all thumbs to size and place them
    NSUInteger i, count = [_photoThumbnailViews count];
    for (i = 0; i < count; i++) {
        FGalleryPhotoView *thumbView = [_photoThumbnailViews objectAtIndex:i];
        [thumbView setBackgroundColor:[UIColor grayColor]];
        
        // create new frame
        thumbView.frame = CGRectMake( dx, dy, kThumbnailSize, kThumbnailSize);
        
        // increment position
        dx += kThumbnailSize + kThumbnailSpacing;
        
        // check if we need to move to a different row
        if( dx + kThumbnailSize + kThumbnailSpacing > _thumbsView.frame.size.width - kThumbnailSpacing )
        {
            dx = 0.0;
            dy += kThumbnailSize + kThumbnailSpacing;
        }
    }
    
    // set the content size of the thumb scroller
    [_thumbsView setContentSize:CGSizeMake( _thumbsView.frame.size.width - ( kThumbnailSpacing*2 ), dy + kThumbnailSize + kThumbnailSpacing )];
}

- (void)handleThumbClick:(id)sender
{
    FGalleryPhotoView *photoView = (FGalleryPhotoView*)[(UIButton*)sender superview];
    [self hideThumbnailViewWithAnimation:YES];
    [self loadPage:(int)photoView.tag];
    _currentPage = (int)photoView.tag;
    _uil_numLabel.text = [NSString stringWithFormat:@"%i of %i", (int)_currentPage+1, itemsNum];
    _uil_caption.text = [[[arr_captions objectAtIndex: _currentPage] lowercaseString] capitalizedString];
    [self checkPageViewContentType];
}

//----------------------------------------------------
#pragma mark - Set up bottom View
//----------------------------------------------------
-(void)createBottomView
{
    _uiv_bottomView = [[UIView alloc] initWithFrame:CGRectMake(0.0, view_height - kBottomViewHeight, view_width, kBottomViewHeight)];
    _uiv_bottomView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    [self.view addSubview: _uiv_bottomView];
    
    _uil_caption = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 0.0, 500.0, kBottomViewHeight)];
    _uil_caption.backgroundColor = [UIColor clearColor];
    [_uil_caption setText:[[[arr_captions objectAtIndex:_currentPage] lowercaseString] capitalizedString]];
    [_uil_caption setTextColor: [UIColor blackColor]];
    _uil_caption.font = [UIFont systemFontOfSize:13.0];
    [_uiv_bottomView addSubview: _uil_caption];
}

//----------------------------------------------------
#pragma mark - PageViewController

#pragma mark Set up page view
//----------------------------------------------------
- (embModelController *)modelController
{
    // Return the model controller object, creating it if necessary.
    // In more complex implementations, the model controller may be passed to the view controller.
    if (!_modelController) {
        _modelController = [[embModelController alloc] initWithImage:arr_images];
    }
    return _modelController;
}

-(void)initPageView:(NSInteger)index {
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:40.0f] forKey:UIPageViewControllerOptionInterPageSpacingKey]];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self.modelController;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews =YES;
    self.pageViewController.view.frame = CGRectMake(0.0, 0.0, view_width, view_height);//self.view.bounds;
    [self.pageViewController didMoveToParentViewController:self];
    [self addChildViewController:self.pageViewController];
    [self.view addSubview: self.pageViewController.view];
    [self.pageViewController.view setBackgroundColor:[UIColor whiteColor]];
    [self loadPage:(int)index];
}

-(void)loadPage:(int)page {
    embDataViewController *startingViewController = [self.modelController viewControllerAtIndex:page storyboard:[UIStoryboard storyboardWithName:@"Main" bundle:nil] andFrame:CGRectMake(0.0, 0.0, view_width, view_height)];
    
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
}

//----------------------------------------------------
#pragma mark update page index
//----------------------------------------------------
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    [self removePlayButton];
}

- (void)pageViewController:(UIPageViewController *)pvc didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    // If the page did not turn
    if (!completed)
    {
        // You do nothing because whatever page you thought you were on
        // before the gesture started is still the correct page
        NSLog(@"same page");
        [self checkPageViewContentType];
        return;
    }
    // This is where you would know the page number changed and handle it appropriately
    [self setpageIndex];
}

/*
    Up date panel's title text
 */
- (void) setpageIndex
{
    embDataViewController *theCurrentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
    int index = (int)[self.modelController indexOfViewController:theCurrentViewController];
    _currentPage = index;
    _uil_numLabel.text = [NSString stringWithFormat:@"%i of %i", (int)_currentPage+1, itemsNum];
    _uil_caption.text = [[[arr_captions objectAtIndex: _currentPage] lowercaseString] capitalizedString];
    [self checkPageViewContentType];
}

//----------------------------------------------------
#pragma mark - Check current content type
//----------------------------------------------------
- (void)checkPageViewContentType
{
    if ([arr_fileType[_currentPage] isEqualToString:@"movie"]) {
        [self createPlayIcon];
    }
}

//----------------------------------------------------
#pragma mark Create play icon for movie files
//----------------------------------------------------

- (void)createPlayIcon
{
    _uiiv_playMovie = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_icon.png"]];
    _uiiv_playMovie.frame = CGRectMake(0.0, 0.0, _uiiv_playMovie.frame.size.width, _uiiv_playMovie.frame.size.height);
    _uiiv_playMovie.center = self.view.center;
    _uiiv_playMovie.contentMode = UIViewContentModeScaleAspectFit;
    [_pageViewController.view addSubview: _uiiv_playMovie];
    UIViewController *viewController = _pageViewController.viewControllers[0];
    [viewController.view viewWithTag:100].userInteractionEnabled = NO;
}
// Remove the play icon image when change page or load thumbs view
- (void)removePlayButton
{
    [_uiiv_playMovie removeFromSuperview];
    _uiiv_playMovie = nil;
}

//----------------------------------------------------
#pragma mark Actions for other type of files
//----------------------------------------------------

//----------------------------------------------------
#pragma mark - Set Tap Gesture
//----------------------------------------------------
- (void)addGestureToView
{
    self.view.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapOnView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnView:)];
    tapOnView.numberOfTapsRequired = 1;
    tapOnView.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer: tapOnView];
    
    //Alloc a double tap (does nothing) to avoid confliction between zooming and hiding top view
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] init];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer: doubleTap];
    [tapOnView requireGestureRecognizerToFail:doubleTap];
}

- (void)tapOnView:(UIGestureRecognizer *)gesture
{
    // If current type is movie, then play the file
    if ([arr_fileType[_currentPage] isEqualToString:@"movie"] ) {
        // Replace the alert code to play movie code
        UIAlertView *alert =  [[UIAlertView alloc] initWithTitle:@"Movie"
                                                         message:@"Should play a movie"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    //If current type is image, tap to hide top and bottom views
    if (!_uiv_topView.hidden) {
        [UIView animateWithDuration:0.33
                         animations:^{
                             _uiv_topView.alpha = 0.0;
                             _uiv_bottomView.alpha = 0.0;
                             _pageViewController.view.backgroundColor = [UIColor blackColor];
                         }
                         completion:^(BOOL finished){
                             _uiv_topView.hidden = YES;
                             _uiv_bottomView.hidden = YES;
                         }];
    }
    else {
        _uiv_topView.hidden = NO;
        _uiv_bottomView.hidden = NO;
        [UIView animateWithDuration:0.33
                         animations:^{
                             _uiv_topView.alpha = 1.0;
                             _uiv_bottomView.alpha = 1.0;
                             _pageViewController.view.backgroundColor = [UIColor whiteColor];
                         }];
    }
}

//----------------------------------------------------
#pragma mark - Clean memory
//----------------------------------------------------
- (void)viewDidDisappear:(BOOL)animated
{
    [_uiv_topView removeFromSuperview];
    _uiv_topView = nil;
    
    [_uil_numLabel removeFromSuperview];
    _uil_numLabel = nil;
    
    [_uib_back removeFromSuperview];
    _uib_back = nil;
    
    [_uiv_bottomView removeFromSuperview];
    _uiv_bottomView = nil;
    
    [_uil_caption removeFromSuperview];
    _uil_caption = nil;
    
    _modelController = nil;
    
    [_photoThumbnailViews removeAllObjects];
    _photoThumbnailViews = nil;
    
    [_thumbsView removeFromSuperview];
    _thumbsView = nil;
    
    [_uiiv_playMovie removeFromSuperview];
    _uiiv_playMovie = nil;
    
    _isThumbViewShowing = NO;
    
    for (UIView __strong *tmp in [_pageViewController.view subviews]) {
        [tmp removeFromSuperview];
        tmp = nil;
    }
    
    [_pageViewController.view removeFromSuperview];
    _pageViewController.view = nil;
    [_pageViewController removeFromParentViewController];
    _pageViewController = nil;
    
    [arr_images removeAllObjects];
    arr_images = nil;
    
    [arr_captions removeAllObjects];
    arr_captions = nil;
    
    [arr_fileType removeAllObjects];
    arr_fileType = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
