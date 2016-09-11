//
//  MetalImageGaussianFilter.h
//  MetalImage
//
//  Created by xuqing on 27/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImageFilter.h"

@interface MetalImageGaussianFilter : MetalImageFilter
@property (nonatomic, assign) float radius; // Default value 0.0
@property (nonatomic, assign) float sigma;  // Default value 0.0

@end
