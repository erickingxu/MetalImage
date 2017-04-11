//
//  MetalImageBrightnessFilter.m
//  MetalImage
//
//  Created by erickingxu on 25/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageBrightnessFilter.h"

@implementation MetalImageBrightnessFilter
{
    id <MTLBuffer>                  _brightnessBuffer;
    simd::float3                    rgbBrightness;
}


-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"brightness";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    
    rgbBrightness             = {0.2, 0.0, 0.0};
    _brightnessBuffer         = [self.filterDevice newBufferWithBytes:&rgbBrightness length:sizeof(simd::float3) options:MTLResourceOptionCPUCacheModeDefault];
    
    return self;
}

-(void)setbrightnessBuffer:(float*)brightArr
{
    rgbBrightness  = {brightArr[0], brightArr[1], brightArr[2]};
    _brightnessBuffer           = [self.filterDevice newBufferWithBytes:&rgbBrightness length:sizeof(simd::float3) options:MTLResourceOptionCPUCacheModeDefault];
}



-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    
    if (commandBuffer && _caclpipelineState)
    {
        id <MTLComputeCommandEncoder>  cmputEncoder = [commandBuffer computeCommandEncoder];
        if (cmputEncoder)
        {
            [cmputEncoder  setComputePipelineState:_caclpipelineState];
            [cmputEncoder setTexture: firstInputTexture.texture atIndex:0];
            [cmputEncoder setTexture: outputTexture.texture atIndex:1];
            [cmputEncoder setBuffer:_brightnessBuffer offset:0 atIndex:0];
            [cmputEncoder dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder endEncoding];
            
        }
    }
    //end if
}



@end
