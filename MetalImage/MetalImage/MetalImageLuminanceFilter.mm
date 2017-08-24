//
//  MetalImageLuminanceFilter.m
//  MetalImage
//
//  Created by erickingxu on 25/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageLuminanceFilter.h"
#import <simd/simd.h>

@implementation MetalImageLuminanceFilter
{
    id <MTLBuffer>              _LumfactorBuffer;
    float                lumfactor;
}

-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"Luminance";
    peline.vertexFuncNameStr  = @"";
    peline.fragmentFuncNameStr= @"";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    lumfactor      = 0.5;
    
    _LumfactorBuffer  = [self.filterDevice newBufferWithBytes:&lumfactor length:sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];

    return self;
}


-(void)setLuminanceBuffer:(float)lum;
{
    lumfactor      = lum;
    if (!self.filterDevice)
    {
        return ;
    }
    
    _LumfactorBuffer  = [self.filterDevice newBufferWithBytes:&lumfactor length:sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];

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
