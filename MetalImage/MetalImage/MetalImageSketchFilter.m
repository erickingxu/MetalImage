//
//  MetalImageSketchFilter.m
//  MetalImage
//
//  Created by xuqing on 13/9/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#import "MetalImageSketchFilter.h"

@implementation MetalImageSketchFilter


-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.vertexFuncNameStr  =  @"";
    peline.fragmentFuncNameStr=  @"";
    peline.computeFuncNameStr =  @"imgSketch";
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
    //end if
    if (commandBuffer && _caclpipelineState)
    {
        id <MTLComputeCommandEncoder>  cmputEncoder = [commandBuffer computeCommandEncoder];
        if (cmputEncoder)
        {
            [cmputEncoder  setComputePipelineState:_caclpipelineState];
            [cmputEncoder  setTexture: firstInputTexture.texture atIndex:0];
            [cmputEncoder  setTexture: outputTexture.texture atIndex:1];
            //[cmputEncoder  setBuffer:  _intensity offset:0 atIndex:0];
            [cmputEncoder  dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder  endEncoding];
            
        }
    }
}
@end
