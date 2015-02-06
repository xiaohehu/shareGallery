//
//  ebZoomingScrollView.h
//  quadrangle
//
//  Created by Evan Buxton on 6/27/13.
//  Copyright (c) 2013 neoscape. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ebZoomingScrollView;

@protocol ebZoomingScrollViewDelegate
-(void)didRemove:(ebZoomingScrollView *)customClass;

@end

@interface ebZoomingScrollView : UIView <UIScrollViewDelegate,UIGestureRecognizerDelegate>
{
	CGFloat maximumZoomScale;
	CGFloat minimumZoomScale;
}

- (id)initWithFrame:(CGRect)frame image:(UIImage*)thisImage shouldZoom:(BOOL)zoomable;
@property (assign) BOOL canZoom;

@property (nonatomic, strong) UIImageView *blurView;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
// define delegate property
@property (nonatomic, assign) id  delegate;
@property (nonatomic, readwrite) BOOL  closeBtn;

// define public functions
-(void)didRemove;
-(void)resetScroll;
@end

