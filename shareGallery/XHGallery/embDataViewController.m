//
//  embDataViewController.m
//  Example
//
//  Created by Evan Buxton on 11/23/13.
//  Copyright (c) 2013 neoscape. All rights reserved.
//

#import "embDataViewController.h"
#import "ebZoomingScrollView.h"
//#import "motionImageViewController.h"

@interface embDataViewController ()
{

}

@property (nonatomic, strong) ebZoomingScrollView			*zoomingScroll;
@property (nonatomic, strong) UIView						*uiv_PlanDataContainer;
@property (nonatomic, strong) UIImage						*uii_PlanData;
@property (nonatomic, strong) UIImageView					*uiiv_PlanData;

@end

@implementation embDataViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.view.frame = [[UIScreen mainScreen] bounds];
	// Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor clearColor];
}

//----------------------------------------------------
#pragma mark - LAYOUT FLOOR PLAN DATA
//----------------------------------------------------
-(void)loadDataAndView
{
    if (!_zoomingScroll) {
        CGRect theFrame = self.view.bounds;
        _zoomingScroll = [[ebZoomingScrollView alloc] initWithFrame:theFrame image:nil shouldZoom:YES];
        [self.view addSubview:_zoomingScroll];
        _zoomingScroll.backgroundColor = [UIColor clearColor];
        _zoomingScroll.delegate=self;
        _zoomingScroll.tag = 100;
    }
    
    // plan info data
    NSString *planName = self.dataObject;
    [self loadInImge:planName];
}

-(void)loadInImge:(NSString *)imageName
{
//    [UIView animateWithDuration:0.0 animations:^{
//        _zoomingScroll.blurView.alpha = 0.0;
//    } completion:^(BOOL finished){
        _zoomingScroll.blurView.image = [UIImage imageNamed:imageName];
//        [UIView animateWithDuration:0.3 animations:^{
//            _zoomingScroll.blurView.alpha = 1.0;
//        }];
//    }];
}

//----------------------------------------------------
#pragma mark - BOILERPLATE
//----------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadDataAndView];
	// otherwise plan stays zoomed in
	// when you scroll to new page
	[_zoomingScroll resetScroll];
}

- (void)viewWillDisappear:(BOOL)animated
{

}

- (void)viewDidDisappear:(BOOL)animated
{
    [_zoomingScroll removeFromSuperview];
    _zoomingScroll = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
