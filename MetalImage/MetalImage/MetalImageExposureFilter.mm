//
//  MetalImageExposureFilter.m
//  MetalImage
//
//  Created by erickingxu on 25/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageExposureFilter.h"

@implementation MetalImageExposureFilter
{
    id <MTLBuffer>              _exposureBuffer;
    CGFloat                     exposure;
}


-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"exposure";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    
    exposure               = 0.0;
    if (!self.filterDevice )
    {
        return nil;
    }
    _exposureBuffer  = [self.filterDevice newBufferWithBytes:&exposure length:sizeof(CGFloat) options:MTLResourceOptionCPUCacheModeDefault];
    return self;
}

-(void)setExposeure:(CGFloat)expos;
{
    exposure               = expos;
    if (!self.filterDevice)
    {
        return ;
    }
    _exposureBuffer  = [self.filterDevice newBufferWithBytes:&exposure length:sizeof(CGFloat) options:MTLResourceOptionCPUCacheModeDefault];
}


-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    
    if (commandBuffer && _caclpipelineState)
    {
        id <MTLComputeCommandEncoder>  cmputEncoder = [commandBuffer computeCommandEncoder];
        if (cmputEncoder)
        {
            [cmputEncoder  setComputePipelineState:_caclpipelineState];
            [cmputEncoder  setTexture: firstInputTexture.texture atIndex:0];
            [cmputEncoder  setTexture: outputTexture.texture atIndex:1];
            [cmputEncoder  setBuffer:  _exposureBuffer offset:0 atIndex:0];
            [cmputEncoder  dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder  endEncoding];
            
        }
    }
    //end if
}

@end
