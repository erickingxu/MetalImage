//
//  MetalImageGrayFilter.m
//  MetalImage
//
//  Created by erickingxu on 12/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageGrayFilter.h"


@implementation MetalImageGrayFilter

-(id)init
{
        METAL_PIPELINE_STATE peline ;
        peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
        peline.stencilPixelFormat =  MTLPixelFormatInvalid;
        peline.orient             =  kMetalImageNoRotation;
        peline.sampleCount        =  1;
        peline.computeFuncNameStr =  @"grayscale";
        peline.vertexFuncNameStr  = @"";
        peline.fragmentFuncNameStr= @"";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }

    return self;
}


@end
