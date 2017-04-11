//
//  MetalImageSaturationFilter.m
//  MetalImage
//
//  Created by erickingxu on 25/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageSaturationFilter.h"
#import <simd/simd.h>

@implementation MetalImageSaturationFilter
{
    id <MTLBuffer>                  _saturationBuffer;
    simd::float3                    rgbSaturation;
}


-(id)init
{
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"imgSaturation";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    
    
    rgbSaturation  = {1.0, 0.1, 0.1};
    if (!self.filterDevice )
    {
        return nil;
    }
    
    _saturationBuffer           = [self.filterDevice newBufferWithBytes:&rgbSaturation length:sizeof(simd::float3) options:MTLResourceOptionCPUCacheModeDefault];
    return self;
}

-(void)setSaturationBuffer:(float*)saturationArr
{
    rgbSaturation  = {saturationArr[0], saturationArr[1], saturationArr[2]};
    _saturationBuffer           = [self.filterDevice newBufferWithBytes:&rgbSaturation length:sizeof(simd::float3) options:MTLResourceOptionCPUCacheModeDefault];
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
            [cmputEncoder  setBuffer:  _saturationBuffer offset:0 atIndex:0];
            [cmputEncoder  dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder  endEncoding];
            
        }
    }
    //end if
}

@end
