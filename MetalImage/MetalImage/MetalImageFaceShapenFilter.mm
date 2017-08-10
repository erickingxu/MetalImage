//
//  MetalImageFaceShapenFilter.m
//  MetalImage
//
//  Created by ericking on 7/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//  Paper refer to :http://www.gson.org/thesis/warping-thesis.pdf

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
//////faceBuf<float> [eyeL,eyeR, cntL0, cntR0, radius0, delta0 ,cntL1, cntR1, radius1, delta1, cntL2, cntR2, radius2, delta2, cntL3, cntR3, radius3, delta3]

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

- (void)renderToTextureWithVertices:(const simd::float4 *)vertices textureCoordinates:(const simd::float2 *)textureCoordinates withAttachmentData:(Texture_FrameData*)pFrameData
{
    if (!firstInputTexture)
    {
        return;
    }
    //new output texture for next filter
    if (_threadGroupSize.width == 0 || _threadGroupSize.height == 0 || _threadGroupSize.depth == 0 )
    {
        _threadGroupSize = MTLSizeMake(16, 16, 1);
    }
    //calculate compute kenel's width and height
    
    NSUInteger nthreadWidthSteps  = (firstInputTexture.width + _threadGroupSize.width - 1) / _threadGroupSize.width;
    NSUInteger nthreadHeightSteps = (firstInputTexture.height+ _threadGroupSize.height - 1)/ _threadGroupSize.height;
    _threadGroupCount             = MTLSizeMake(nthreadWidthSteps, nthreadHeightSteps, 1);
    
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        
        if (outputTexture ==  nil)
        {
            outputTexture  = [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight: firstInputTexture.height];
            [outputTexture loadTextureIntoDevice: self.filterDevice];
        }
        
    });
    
    if (outputTexture && ![self initRenderPassDescriptorFromTexture:outputTexture.texture])
    {
        _renderpipelineState = nil;//cant render sth on ouputTexture...
    }
    //load encoder for compute input texture
    
    if (sharedcommandBuffer)
    {
        [self caculateWithCommandBuffer:sharedcommandBuffer];
    }
    
}

@end
