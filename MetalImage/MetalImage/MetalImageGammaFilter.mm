//
//  MetalImageGammaFilter.m
//  MetalImage
//
//  Created by erickingxu on 21/9/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageGammaFilter.h"

@implementation MetalImageGammaFilter
{
    id <MTLBuffer>              _gammaBuffer;
    
}


-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.vertexFuncNameStr  =  @"gammaVertex";
    peline.fragmentFuncNameStr=  @"gammaFragment";
    peline.computeFuncNameStr =  @"";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    

    if (!self.filterDevice )
    {
        return nil;
        
    }
    _gammaBuffer  = [self.filterDevice newBufferWithLength:1024 options:0];
    _gammaBuffer.label = [NSString stringWithFormat:@"ConstUniformBuffer"];
    float* gammaPtr = (float*)[_gammaBuffer contents];
    *gammaPtr = 2.0;
    
    return self;
}

-(void)slideGamma:(CGFloat)val
{
   
    if (!self.filterDevice)
    {
        return ;
    }
    float* gammaPtr = (float*)[_gammaBuffer contents];
    *gammaPtr = val;
}




-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    
    if (commandBuffer && _renderpipelineState)
    {
        if(_renderpipelineState && renderplineStateDescriptor)
        {
            id <MTLRenderCommandEncoder>  renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];//should keep renderPassDescp is ture...

            [renderEncoder pushDebugGroup:@"gamma_filter_render_encoder"];
            [renderEncoder setVertexBuffer:self.verticsBuffer  offset:0  atIndex: 0 ];
            [renderEncoder setVertexBuffer:self.coordBuffer offset:0  atIndex: 1];
            
            [renderEncoder setFragmentTexture:firstInputTexture.texture atIndex:0];
            [renderEncoder setFragmentBuffer:_gammaBuffer offset:0 atIndex:0];

            [renderEncoder setRenderPipelineState:_renderpipelineState];
            
            // tell the render context we want to draw our primitives
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:1];
            
            [renderEncoder endEncoding];
            [renderEncoder popDebugGroup];
        }
    }
    //end if
}

/*
- (void)renderToTextureWithVertices:(const simd::float4 *)vertices textureCoordinates:(const simd::float2 *)textureCoordinates withAttachmentData:(Texture_FrameData*)pFrameData
{
    if (!firstInputTexture)
    {
        return;
    }
    //new output texture for next filter
    outputTexture  = [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight: firstInputTexture.height];
    [outputTexture loadTextureIntoDevice:self.filterDevice];
    
    if (![self initRenderPassDescriptorFromTexture:outputTexture.texture])
    {
        _renderpipelineState = nil;//cant render sth on ouputTexture...
    }
    
    //set output texture and draw reslut to it
    self.verticsBuffer = [self.filterDevice newBufferWithBytes:vertices length:6*sizeof(simd::float4) options:MTLResourceOptionCPUCacheModeDefault];
    
    if(!self.verticsBuffer)
    {
        NSLog(@">> ERROR: Failed creating a vertex buffer for a quad!");
        return ;
    }
    self.verticsBuffer.label = @"quad vertices";
    self.coordBuffer = [self.filterDevice newBufferWithBytes:textureCoordinates length:6*sizeof(simd::float2) options:MTLResourceOptionCPUCacheModeDefault];
    if(!self.coordBuffer)
    {
        NSLog(@">> ERROR: Failed creating a 2d texture coordinate buffer!");
        return;
    }
    self.coordBuffer.label = @"quad texcoords";
    
    //load encoder for compute input texture
    
    if (sharedcommandBuffer)
    {
        [self caculateWithCommandBuffer:sharedcommandBuffer];
    }
    
}
*/
@end
