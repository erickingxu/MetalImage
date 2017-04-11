//
//  MetalImageClipFilter.h
//  MetalImage
//
//  Created by erickingxu on 10/4/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalImageFilter.h"

@interface MetalImageCropFilter : MetalImageFilter


@property(readwrite, nonatomic) CGRect cropRegion;

// Initialization and teardown
- (id)initWithCropRegion:(CGRect)newCropRegion;

@end
