//
//  MetalImageSaturationFilter.h
//  MetalImage
//
//  Created by xuqing on 25/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImageFilter.h"

@interface MetalImageSaturationFilter : MetalImageFilter

-(void)setSaturationBuffer:(float*)saturationArr;

@end
