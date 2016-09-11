//
//  MetalImageContrastFilter.m
//  MetalImage
//
//  Created by xuqing on 25/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImageContrastFilter.h"

@implementation MetalImageContrastFilter

{
    id <MTLBuffer>              _contrastBuffer;
    CGFloat                     contrastfactor;
}


-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"contrast";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    
    contrastfactor               = 0.0;
    if (!self.filterDevice )
    {
        return nil;
    }
    _contrastBuffer  = [self.filterDevice newBufferWithBytes:&contrastfactor length:sizeof(CGFloat) options:MTLResourceOptionCPUCacheModeDefault];

    return self;
}

-(void)setContrastFactor:(CGFloat)contrst
{
    contrastfactor               = contrst;
    if (!self.filterDevice )
    {
        return ;
    }
    _contrastBuffer  = [self.filterDevice newBufferWithBytes:&contrastfactor length:sizeof(CGFloat) options:MTLResourceOptionCPUCacheModeDefault];
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
            [cmputEncoder  setBuffer:  _contrastBuffer offset:0 atIndex:0];
            [cmputEncoder  dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder  endEncoding];
            
        }
    }
    //end if
}

@end
