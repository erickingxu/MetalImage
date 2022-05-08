//
//  MetalImagePointSpirit.m
//  MetalImage
//
//  Created by ericking on 16/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#import "MetalImagePointSpirit.h"
static const simd::float4 points[3] = {
    { -0.2f,  -0.8f, 0.0f, 1.0f },
    {  0.5f,  -0.5f, 0.0f, 1.0f },
    { -0.4f,   0.9f, 0.0f, 1.0f }
    
};
@implementation MetalImagePointSpirit


-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.vertexFuncNameStr  =  @"pointSpiritVertex";
    peline.fragmentFuncNameStr=  @"roundSpiritFragment";
    peline.computeFuncNameStr =  @"";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    
    
    if (!self.filterDevice )
    {
        return nil;
        
    }
    self.verticsBuffer = [self.filterDevice newBufferWithBytes:&points[0] length:12*sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    
    return self;
}


-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    [filterCommandQueue.sharedCommandQueue insertDebugCaptureBoundary];
    if (commandBuffer && _renderpipelineState)
    {
        if(_renderpipelineState && renderplineStateDescriptor)
        {
            
            id <MTLRenderCommandEncoder>  renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];//should keep renderPassDescp is ture...
            
            [renderEncoder pushDebugGroup:@"points_render_encoder"];
            [renderEncoder setVertexBuffer:self.verticsBuffer  offset:0  atIndex: 0 ];
            
            [renderEncoder setRenderPipelineState:_renderpipelineState];
            
            // tell the render context we want to draw our primitives
            [renderEncoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:0 vertexCount:3 instanceCount:1];
            
            [renderEncoder endEncoding];
            [renderEncoder popDebugGroup];
        }
        if(outputTexture)
        {
            outputTexture = firstInputTexture;
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
        NSInteger w = _caclpipelineState.threadExecutionWidth;
        NSInteger h = _caclpipelineState.maxTotalThreadsPerThreadgroup / w;
        _threadGroupSize = MTLSizeMake(w, h, 1);
    }
    //calculate compute kenel's width and height
    
    NSUInteger nthreadWidthSteps  = (firstInputTexture.width + _threadGroupSize.width - 1) / _threadGroupSize.width;
    NSUInteger nthreadHeightSteps = (firstInputTexture.height+ _threadGroupSize.height - 1)/ _threadGroupSize.height;
    _threadGroupCount             = MTLSizeMake(nthreadWidthSteps, nthreadHeightSteps, 1);
    
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        
        if (outputTexture ==  nil)
        {
            outputTexture  = [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight: firstInputTexture.height withFormat:MTLPixelFormatRGBA8Unorm];
            [outputTexture loadTextureIntoDevice:self.filterDevice];
        }
        
    });
    
    if (outputTexture)
    {
        //outputTexture.texture = firstInputTexture.texture;
        if (![self initRenderPassDescriptorFromTexture:firstInputTexture.texture])
        {
            _renderpipelineState = nil;//cant render sth on ouputTexture...
        }
        
    }
    
    //load encoder for compute input texture
    if (sharedcommandBuffer)
    {
        [self caculateWithCommandBuffer:sharedcommandBuffer];
    }
    
}

//////draw filter pass to view for assigned texture
-(BOOL)initRenderPassDescriptorFromTexture:(id <MTLTexture>)textureForOutput
{
    if (nil == renderPassDescriptor)//could be resue....
    {
        renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
    }
    MTLRenderPassColorAttachmentDescriptor* colorAttachment  = renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture         = textureForOutput;//target for draw
    colorAttachment.loadAction      = MTLLoadActionLoad;
    colorAttachment.clearColor      = MTLClearColorMake(0.0, 0.0, 0.0, 0.5);//black
    colorAttachment.storeAction     = MTLStoreActionStore;
    
    //using default depth and stencil dscrptor...
    
    return YES;
}

@end
