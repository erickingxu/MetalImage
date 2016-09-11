//
//  MetalImageLuminanceFilter.m
//  MetalImage
//
//  Created by xuqing on 25/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImageLuminanceFilter.h"
#import <simd/simd.h>

@implementation MetalImageLuminanceFilter
{
    id <MTLBuffer>              _LumfactorBuffer;
    simd::float3                lumfactorArr;
}

-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"Luminance";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    lumfactorArr      = {1.0, 0.1, 0.0};
    
    _LumfactorBuffer  = [self.filterDevice newBufferWithBytes:&lumfactorArr length:sizeof(simd::float3) options:MTLResourceOptionCPUCacheModeDefault];

    return self;
}


-(void)setLuminanceBuffer:(float*)lumArr;
{
    lumfactorArr      = {lumArr[0], lumArr[1], lumArr[2]};
    if (!self.filterDevice)
    {
        return ;
    }
    
    _LumfactorBuffer  = [self.filterDevice newBufferWithBytes:&lumfactorArr length:sizeof(simd::float3) options:MTLResourceOptionCPUCacheModeDefault];

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
            [cmputEncoder  setBuffer:  _LumfactorBuffer offset:0 atIndex:0];
            [cmputEncoder  dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder  endEncoding];
            
        }
    }
    //end if
}

@end
