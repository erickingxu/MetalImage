//
//  MetalImageFilter.m
//  MetalImage
//
//  Created by xuqing on 1/8/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImageFilter.h"


#define kCntQuadTexCoords   6

@implementation MetalImageFilter

@synthesize filterDevice     = _filterDevice;
@synthesize verticsBuffer       = _verticsBuffer;
@synthesize coordBuffer         = _coordBuffer;
@synthesize filterLibrary       = _filterLibrary;
@synthesize depthPixelFormat    = _depthPixelFormat;
@synthesize stencilPixelFormat  = _stencilPixelFormat;

-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr = @""; //"basePass";
    peline.vertexFuncNameStr  = @"imageQuadVertex";
    peline.fragmentFuncNameStr= @"imageQuadFragment";
    if ( !(self = [self initWithMetalPipeline: &peline]) || !_filterDevice)
    {
        return nil;
    }

    return self;
}

-(id)initWithMetalPipeline:(METAL_PIPELINE_STATE*)pline
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    if (!_filterDevice)
    {
        _filterDevice = [MetalImageCmdQueue getGlobalDevice];
    }
    _filterLibrary      = [_filterDevice newDefaultLibrary];
    if (!_filterLibrary)
    {
        return nil;
    }
    _depthPixelFormat   = pline->depthPixelFormat;
    _stencilPixelFormat = pline->stencilPixelFormat;
    //_bFBOOnly           = NO;
    firstInputTexture   = nil;
    outputTexture       = nil;
    inputRotation       = pline->orient;
    renderplineStateDescriptor = [MTLRenderPipelineDescriptor new];
    renderDepthStateDesc = [MTLDepthStencilDescriptor new];
    
    if (![self preparePipelineState:pline] )
    {
        return nil;
    }
    return self;
}


- (BOOL) preparePipelineState:(METAL_PIPELINE_STATE*)filterPipelineState
{
    // get the vertex function from the library
    if (!_filterLibrary && _filterDevice)
    {
        NSError *liberr = nil;
        _filterLibrary = [_filterDevice newLibraryWithFile:@"imageQuad.metallib" error:&liberr];
        if (!_filterLibrary)
        {
            return NO;
        }
    }
    NSError *pError = nil;
    if ([filterPipelineState->computeFuncNameStr isEqualToString:@""] && ![filterPipelineState->fragmentFuncNameStr isEqualToString:@""])
    {///just do render pipeline, no compute encoder...
        id <MTLFunction> vetexFunc = [_filterLibrary newFunctionWithName:filterPipelineState->vertexFuncNameStr];
        id <MTLFunction> fragFunc  = [_filterLibrary newFunctionWithName:filterPipelineState->fragmentFuncNameStr];
       
        renderplineStateDescriptor.depthAttachmentPixelFormat   = MTLPixelFormatInvalid;//filterPipelineState->depthPixelFormat;
        renderplineStateDescriptor.stencilAttachmentPixelFormat = filterPipelineState->stencilPixelFormat;
        renderplineStateDescriptor.colorAttachments[0].pixelFormat= MTLPixelFormatBGRA8Unorm;
        renderplineStateDescriptor.sampleCount                  = filterPipelineState->sampleCount;
        renderplineStateDescriptor.vertexFunction               = vetexFunc;
        renderplineStateDescriptor.fragmentFunction             = fragFunc;
        
        _renderpipelineState  = [_filterDevice newRenderPipelineStateWithDescriptor:renderplineStateDescriptor error:&pError];
        MTLRenderPassDescriptor* _renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
        
        if (!_renderpipelineState)
        {
            NSLog(@">>ERROR: Failed create renderpipeline in base filter! error is :%@",pError);
            return NO;
        }
        return YES;
    }
    else
    {
        id <MTLFunction> caculateFunc   = [_filterLibrary newFunctionWithName:filterPipelineState->computeFuncNameStr];
        
        _caclpipelineState   = [_filterDevice newComputePipelineStateWithFunction:caculateFunc error:&pError];
        
        if(!_caclpipelineState)
        {
            NSLog(@">> ERROR: Failed acquiring compute pipeline state descriptor: %@", pError);
            
            return NO;
        }
    }
    return YES;
}

+ (const simd::float2 *)textureCoordinatesForRotation:(MetalImageRotationMode)rotationMode
{
    static const simd::float2 noRotationTextureCoordinates[] = {
        {0.0f, 0.0f},
        {1.0f, 0.0f},
        {0.0f, 1.0f},
        
        {1.0f, 0.0f},
        {0.0f, 1.0f},
        {1.0f, 1.0f}
    };
    
    static const simd::float2 rotateLeftTextureCoordinates[] = {
        {1.0f, 0.0f},
        {1.0f, 1.0f},
        {0.0f, 0.0f},
        
        {1.0f, 1.0f},
        {0.0f, 0.0f},
        {0.0f, 1.0f},
    };
    
    static const simd::float2 rotateRightTextureCoordinates[] = {
        {0.0f, 1.0f},
        {0.0f, 0.0f},
        {1.0f, 1.0f},
        
        {0.0f, 0.0f},
        {1.0f, 1.0f},
        {1.0f, 0.0f},
    };
    
    static const simd::float2 verticalFlipTextureCoordinates[] = {
        {0.0f, 1.0f},
        {1.0f, 1.0f},
        {0.0f, 0.0f},
        
        {1.0f,  1.0f},
        {0.0f,  0.0f},
        {1.0f,  0.0f},
    };
    
    static const simd::float2 horizontalFlipTextureCoordinates[] = {
        {1.0f,  0.0f},
        {0.0f,  0.0f},
        {1.0f,  1.0f},
        
        {0.0f,  0.0f},
        {1.0f,  1.0f},
        {0.0f,  1.0f},
    };
    
    static const simd::float2 rotateRightVerticalFlipTextureCoordinates[] = {
        {0.0f, 0.0f},
        {0.0f, 1.0f},
        {1.0f, 0.0f},
        
        {0.0f, 1.0f},
        {1.0f, 0.0f},
        {1.0f, 1.0f},
    };
    
    static const simd::float2 rotateRightHorizontalFlipTextureCoordinates[] = {
        {1.0f, 1.0f},
        {1.0f, 0.0f},
        {0.0f, 1.0f},
        
        {1.0f, 0.0f},
        {0.0f, 1.0f},
        {0.0f, 0.0f},
    };
    
    static const simd::float2 rotate180TextureCoordinates[] = {
        {1.0f, 1.0f},
        {0.0f, 1.0f},
        {1.0f, 0.0f},
        
        {0.0f, 1.0f},
        {1.0f, 0.0f},
        {0.0f, 0.0f},
    };
    switch(rotationMode)
    {
        case kMetalImageNoRotation:
            return noRotationTextureCoordinates;
        case kMetalImageRotateLeft:
            return rotateLeftTextureCoordinates;
        case kMetalImageRotateRight:
            return rotateRightTextureCoordinates;
        case kMetalImageFlipVertical:
            return verticalFlipTextureCoordinates;
        case kMetalImageFlipHorizonal:
            return horizontalFlipTextureCoordinates;
        case kMetalImageRotateRightFlipVertical:
            return rotateRightVerticalFlipTextureCoordinates;
        case kMetalImageRotateRightFlipHorizontal:
            return rotateRightHorizontalFlipTextureCoordinates;
        case kMetalImageRotate180:
            return rotate180TextureCoordinates;
    }
}



- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    static const simd::float4 imageVertices[] = {
        { -1.0f,  -1.0f, 0.0f, 1.0f },
        {  1.0f,  -1.0f, 0.0f, 1.0f },
        { -1.0f,   1.0f, 0.0f, 1.0f },
        
        {  1.0f,  -1.0f, 0.0f, 1.0f },
        { -1.0f,   1.0f, 0.0f, 1.0f },
        {  1.0f,   1.0f, 0.0f, 1.0f },
    };
    
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
}

//////draw filter pass to view for assigned texture
-(BOOL)initRenderPassDescriptorFromTexture:(id <MTLTexture>)textureForOutput
{
    if (nil == renderPassDescriptor)//could be resue....
    {
        renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
    }
    MTLRenderPassColorAttachmentDescriptor    *colorAttachment  = renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture         = textureForOutput;//target for draw
    colorAttachment.loadAction      = MTLLoadActionClear;
    colorAttachment.clearColor      = MTLClearColorMake(0.0, 0.0, 1.0, 0.5);//black
    colorAttachment.storeAction     = MTLStoreActionStore;
    //using default depth and stencil dscrptor...
    
    if(!renderDepthStateDesc)
    {
        NSLog(@">> ERROR: Failed creating a depth stencil descriptor!");
        
        return NO;
    } // if
    
    renderDepthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    renderDepthStateDesc.depthWriteEnabled    = YES;
    
    _depthStencilState = [_filterDevice newDepthStencilStateWithDescriptor:renderDepthStateDesc];
    
    if(!_depthStencilState)
    {
        return NO;
    } // if
    
    return YES;
}


-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    
    if (commandBuffer)
    {
        if(_renderpipelineState && renderplineStateDescriptor)
        {
            id <MTLRenderCommandEncoder>  renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];//should keep renderPassDescp is ture...
            
            [renderEncoder pushDebugGroup:@"base_filter_render_encoder"];
            [renderEncoder setDepthStencilState:_depthStencilState];
            [renderEncoder setFragmentTexture:firstInputTexture.texture atIndex:0];//first render pass for next pass using...
            [renderEncoder setVertexBuffer:_verticsBuffer  offset:0  atIndex: 0 ];
            [renderEncoder setVertexBuffer:_coordBuffer offset:0  atIndex: 1];
            
            [renderEncoder setRenderPipelineState:_renderpipelineState];
            
            // tell the render context we want to draw our primitives
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:1];
            
            [renderEncoder endEncoding];
            [renderEncoder popDebugGroup];
        }
        else if( _caclpipelineState)
        {
            id <MTLComputeCommandEncoder>  computeEncoder = [commandBuffer computeCommandEncoder];
            [computeEncoder  setComputePipelineState:_caclpipelineState];
            [computeEncoder setTexture: firstInputTexture.texture atIndex:0];
            [computeEncoder setTexture: outputTexture.texture atIndex:1];
            [computeEncoder dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [computeEncoder endEncoding];
            
        }
       
    }
    //end if
}


- (void)renderToTextureWithVertices:(const simd::float4 *)vertices textureCoordinates:(const simd::float2 *)textureCoordinates
{
    if (!firstInputTexture)
    {
        return;
    }
    //calculate compute kenel's width and height
    _threadGroupSize = MTLSizeMake(16, 16, 1);
    NSUInteger nthreadWidthSteps  = (firstInputTexture.width + _threadGroupSize.width - 1) / _threadGroupSize.width;
    NSUInteger nthreadHeightSteps = (firstInputTexture.height+ _threadGroupSize.height - 1)/ _threadGroupSize.height;
    _threadGroupCount             = MTLSizeMake(nthreadWidthSteps, nthreadHeightSteps, 1);
    
    //new output texture for next filter
    outputTexture  = [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight: firstInputTexture.height];
    [outputTexture loadTextureIntoDevice:_filterDevice];
    if (![self initRenderPassDescriptorFromTexture:outputTexture.texture])
    {
        _renderpipelineState = nil;//cant render sth on ouputTexture...
    }
 
    //set output texture and draw reslut to it
    _verticsBuffer = [_filterDevice newBufferWithBytes:vertices length:kCntQuadTexCoords*sizeof(simd::float4) options:MTLResourceOptionCPUCacheModeDefault];
    
    if(!_verticsBuffer)
    {
        NSLog(@">> ERROR: Failed creating a vertex buffer for a quad!");
        return ;
    }
    _verticsBuffer.label = @"quad vertices";
    _coordBuffer = [_filterDevice newBufferWithBytes:textureCoordinates length:kCntQuadTexCoords*sizeof(simd::float2) options:MTLResourceOptionCPUCacheModeDefault];
    if(!_coordBuffer)
    {
        NSLog(@">> ERROR: Failed creating a 2d texture coordinate buffer!");
        return;
    }
    _coordBuffer.label = @"quad texcoords";
    
    //load encoder for compute input texture
  
    if (sharedcommandBuffer)
    {
        [self caculateWithCommandBuffer:sharedcommandBuffer];
    }
    
}

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime
{
    // Get all targets the framebuffer so they can grab a lock on it
    for (id<MetalImageInput> currentTarget in targets)
    {
        if (currentTarget) //!= self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [self setInputTextureForTarget:currentTarget atIndex:textureIndex];
            //[currentTarget setInputSize:[self outputFrameSize] atIndex:textureIndex];
            [self setInputCommandBufferForTarget:currentTarget atIndex:textureIndex];
        }
    }
    // Trigger processing last, so that our unlock comes first in serial execution, avoiding the need for a callback
    for (id<MetalImageInput> currentTarget in targets)
    {
        if (currentTarget )//!= self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

-(void)setInputTexture:(MetalImageTexture *)newInputTexture atIndex:(NSInteger)textureIndex
{
    firstInputTexture  = newInputTexture;//last filter's output texture
}

- (CGSize)outputFrameSize
{
    return CGSizeMake(0, 0);///should rewrite...
}
- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}
@end
