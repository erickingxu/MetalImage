//
//  MetalImageFaceShapenFilter.m
//  MetalImage
//
//  Created by xuqing on 7/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#import "MetalImageFaceShapenFilter.h"

@implementation MetalImageFaceShapenFilter

-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"faceSharpen";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    

    if (!self.filterDevice )
    {
        return nil;
    }
    return self;
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

            [cmputEncoder  dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder  endEncoding];
            
        }
    }
    //end if
}

//////////
-(void)loadFrameData: (uint8_t*)baseAddress  withFormat:(int)fmt withWidth: (uint32_t)width withHeight: (uint32_t)height inBytesPerRow: (uint32_t)bytesPerRow
{
    
}
@end
