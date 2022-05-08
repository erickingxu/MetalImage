//
//  MetalImageCropFilter.m
//  MetalImage
//
//  Created by erickingxu on 10/4/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#import "MetalImageCropFilter.h"

@implementation MetalImageCropFilter
{
    simd::float2 cropTextureCoordinates[6];
    CGSize  usingSize;
}

@synthesize cropRegion = _cropRegion;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithCropRegion:(CGRect)newCropRegion;
{
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.vertexFuncNameStr  =  @"cropVertex";
    peline.fragmentFuncNameStr=  @"cropFragment";
    peline.computeFuncNameStr =  @"";
    
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    
    
    if (!self.filterDevice )
    {
        return nil;
        
    }
    
    self.cropRegion = newCropRegion;
    usingSize  = CGSizeMake(0, 0);
    return self;
}

- (id)init;
{
    if (!(self = [self initWithCropRegion:CGRectMake(0.0, 0.0, 1.0, 1.0)]))
    {
        return nil;
    }
    
    return self;
}

-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    
    if (commandBuffer && _renderpipelineState)
    {
        if(_renderpipelineState && renderplineStateDescriptor)
        {
            id <MTLRenderCommandEncoder>  renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];//should keep renderPassDescp is ture...
            
            [renderEncoder pushDebugGroup:@"cropRender_encoder"];
            [renderEncoder setVertexBuffer:self.verticsBuffer  offset:0  atIndex: 0 ];
            [renderEncoder setVertexBuffer:self.coordBuffer offset:0  atIndex: 1];
            
            [renderEncoder setFragmentTexture:firstInputTexture.texture atIndex:0];
            [renderEncoder setFragmentTexture:outputTexture.texture atIndex:1];
            [renderEncoder setRenderPipelineState:_renderpipelineState];
            
            // tell the render context we want to draw our primitives
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:1];
            
            [renderEncoder endEncoding];
            [renderEncoder popDebugGroup];
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
    usingSize.width = firstInputTexture.width*_cropRegion.size.width;
    usingSize.height = firstInputTexture.height*_cropRegion.size.height;
    //new output texture for next filter
    outputTexture  = [[MetalImageTexture alloc] initWithWidth: usingSize.width withHeight: usingSize.height withFormat:MTLPixelFormatBGRA8Unorm];
    
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
    
    self.coordBuffer = [self.filterDevice newBufferWithBytes:cropTextureCoordinates length:6*sizeof(simd::float2) options:MTLResourceOptionCPUCacheModeDefault];
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


///Update and set clip region for filter
- (void)setCropRegion:(CGRect)newValue;
{
    NSParameterAssert(newValue.origin.x >= 0 && newValue.origin.x <= 1 &&
                      newValue.origin.y >= 0 && newValue.origin.y <= 1 &&
                      newValue.size.width >= 0 && newValue.size.width <= 1 &&
                      newValue.size.height >= 0 && newValue.size.height <= 1);
    
    _cropRegion = newValue;
    [self calculateCropTextureCoordinates];
}


- (void)calculateCropTextureCoordinates;
{
    CGFloat minX = _cropRegion.origin.x;
    CGFloat minY = _cropRegion.origin.y;
    CGFloat maxX = CGRectGetMaxX(_cropRegion);
    CGFloat maxY = CGRectGetMaxY(_cropRegion);
    
    switch(inputRotation)
    {
        case kMetalImageNoRotation: // Works
        {
            cropTextureCoordinates[0].x = minX; // 0,0
            cropTextureCoordinates[0].y = minY;
            cropTextureCoordinates[1].x = maxX; // 1,0
            cropTextureCoordinates[1].y = minY;
            cropTextureCoordinates[2].x = minX; // 0,1
            cropTextureCoordinates[2].y = maxY;
            
            cropTextureCoordinates[3].x = maxX; // 1,0
            cropTextureCoordinates[3].y = minY;
            cropTextureCoordinates[4].x = minX; // 0,1
            cropTextureCoordinates[4].y = maxY;
            cropTextureCoordinates[5].x = maxX; // 1,1
            cropTextureCoordinates[5].y = maxY;
        };
            break;
        case kMetalImageRotateLeft: // Fixed
        {
            cropTextureCoordinates[0].x = maxY; // 1,0
            cropTextureCoordinates[0].y = 1.0 - maxX;
            cropTextureCoordinates[1].x = maxY; // 1,1
            cropTextureCoordinates[1].y = 1.0 - minX;
            cropTextureCoordinates[2].x = minY; // 0,0
            cropTextureCoordinates[2].y = 1.0 - maxX;
            
            cropTextureCoordinates[3].x = maxY; // 1,1
            cropTextureCoordinates[3].y = 1.0 - minX;
            cropTextureCoordinates[4].x = minY; // 0,0
            cropTextureCoordinates[4].y = 1.0 - maxX;
            cropTextureCoordinates[5].x = minY; // 0,1
            cropTextureCoordinates[5].y = 1.0 - minX;
            
        };
            break;
        case kMetalImageRotateRight: // Fixed
        {
            cropTextureCoordinates[0].x = minY; // 0,1
            cropTextureCoordinates[0].y = 1.0 - minX;
            cropTextureCoordinates[1].x = minY; // 0,0
            cropTextureCoordinates[1].y = 1.0 - maxX;
            cropTextureCoordinates[2].x = maxY; // 1,1
            cropTextureCoordinates[2].y = 1.0 - minX;
            
            cropTextureCoordinates[3].x = minY; // 0,0
            cropTextureCoordinates[3].y = 1.0 - maxX;
            cropTextureCoordinates[4].x = maxY; // 1,1
            cropTextureCoordinates[4].y = 1.0 - minX;
            cropTextureCoordinates[5].x = maxY; // 1,0
            cropTextureCoordinates[5].y = 1.0 - maxX;
            
        };
            break;
        case kMetalImageFlipVertical: // Works for me
        {
            cropTextureCoordinates[0].x = minX; // 0,1
            cropTextureCoordinates[0].y = maxY;
            cropTextureCoordinates[1].x = maxX; // 1,1
            cropTextureCoordinates[1].y = maxY;
            cropTextureCoordinates[2].x = minX; // 0,0
            cropTextureCoordinates[2].y = minY;
            
            cropTextureCoordinates[3].x = maxX; // 1,1
            cropTextureCoordinates[3].y = maxY;
            cropTextureCoordinates[4].x = minX; // 0,0
            cropTextureCoordinates[4].y = minY;
            cropTextureCoordinates[5].x = maxX; // 1,0
            cropTextureCoordinates[5].y = minY;
            
        }; break;
        case kMetalImageFlipHorizonal: // Works for me
        {
            cropTextureCoordinates[0].x = maxX; // 1,0
            cropTextureCoordinates[0].y = minY;
            cropTextureCoordinates[1].x = minX; // 0,0
            cropTextureCoordinates[1].y = minY;
            cropTextureCoordinates[2].x = maxX; // 1,1
            cropTextureCoordinates[2].y = maxY;
            
            cropTextureCoordinates[3].x = minX; // 0,0
            cropTextureCoordinates[3].y = minY;
            cropTextureCoordinates[4].x = maxX; // 1,1
            cropTextureCoordinates[4].y = maxY;
            cropTextureCoordinates[5].x = minX; // 0,1
            cropTextureCoordinates[5].y = maxY;
            
        }; break;
        case kMetalImageRotate180: // Fixed
        {
            cropTextureCoordinates[0].x = maxX; // 1,1
            cropTextureCoordinates[0].y = maxY;
            cropTextureCoordinates[1].x = minX; // 0,1
            cropTextureCoordinates[1].y = maxY;
            cropTextureCoordinates[2].x = maxX; // 1,0
            cropTextureCoordinates[2].y = minY;
            
            cropTextureCoordinates[3].x = minX; // 0,1
            cropTextureCoordinates[3].y = maxY;
            cropTextureCoordinates[4].x = maxX; // 1,0
            cropTextureCoordinates[4].y = minY;
            cropTextureCoordinates[5].x = minX; // 0,0
            cropTextureCoordinates[5].y = minY;
            
        };
            break;
        case kMetalImageRotateRightFlipVertical: // Fixed
        {
            cropTextureCoordinates[0].x = minY; // 0,0
            cropTextureCoordinates[0].y = 1.0 - maxX;
            cropTextureCoordinates[1].x = minY; // 0,1
            cropTextureCoordinates[1].y = 1.0 - minX;
            cropTextureCoordinates[2].x = maxY; // 1,0
            cropTextureCoordinates[2].y = 1.0 - maxX;
            
            cropTextureCoordinates[3].x = minY; // 0,1
            cropTextureCoordinates[3].y = 1.0 - minX;
            cropTextureCoordinates[4].x = maxY; // 1,0
            cropTextureCoordinates[4].y = 1.0 - maxX;
            cropTextureCoordinates[5].x = maxY; // 1,1
            cropTextureCoordinates[5].y = 1.0 - minX;
            
        }; break;
        case kMetalImageRotateRightFlipHorizontal: // Fixed
        {
            cropTextureCoordinates[0].x = maxY; // 1,1
            cropTextureCoordinates[0].y = 1.0 - minX;
            cropTextureCoordinates[1].x = maxY; // 1,0
            cropTextureCoordinates[1].y = 1.0 - maxX;
            cropTextureCoordinates[2].x = minY; // 0,1
            cropTextureCoordinates[2].y = 1.0 - minX;
            
            cropTextureCoordinates[3].x = maxY; // 1,0
            cropTextureCoordinates[3].y = 1.0 - maxX;
            cropTextureCoordinates[4].x = minY; // 0,1
            cropTextureCoordinates[4].y = 1.0 - minX;
            cropTextureCoordinates[5].x = minY; // 0,0
            cropTextureCoordinates[5].y = 1.0 - maxX;
            
        };
            break;
    }
}

@end
