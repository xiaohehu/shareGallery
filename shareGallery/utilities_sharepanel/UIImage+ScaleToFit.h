//
//  UIImage+ScaleToFit.h
//  embCustomAssetPicker
//
//  Created by Evan Buxton on 6/21/14.
//  Copyright (c) 2014 neoscape. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ScaleToFit)
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width;
@end
