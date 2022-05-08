//
//  MetalImageFilter.m
//  MetalImage
//
//  Created by erickingxu on 1/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageFilter.h"


static const simd::float4 imageVertices[] = {
    { -1.0f,  -1.0f, 0.0f, 1.0f },
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    {  1.0f,   1.0f, 0.0f, 1.0f },
};


#define kCntQuadTexCoords   6

@implementation MetalImageFilter

@synthesize filterDevice        = _filterDevice;
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

    _threadGroupSize = MTLSizeMake(16, 16, 1);
    _depthPixelFormat           = pline->depthPixelFormat;
    _stencilPixelFormat         = pline->stencilPixelFormat;
    
    firstInputTexture           = nil;
    outputTexture               = nil;
    inputRotation               = pline->orient;
    renderplineStateDescriptor  = [MTLRenderPipelineDescriptor new];
    renderDepthStateDesc        = [MTLDepthStencilDescriptor new];
    if(!renderDepthStateDesc)
    {
        NSLog(@">> ERROR: Failed creating a depth stencil descriptor!");
        
        return nil;
    } // if
    renderDepthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    renderDepthStateDesc.depthWriteEnabled    = NO;
    
    _depthStencilState = [_filterDevice newDepthStencilStateWithDescriptor:renderDepthStateDesc];
    
    if(!_depthStencilState)
    {
        return nil;
    } // if
    
    //set output texture and draw reslut to it with vertex buffer which could be reused
    const simd::float2 *CoordBytes = [[self class] textureCoordinatesForRotation:inputRotation];
    
    _verticsBuffer = [_filterDevice newBufferWithBytes:imageVertices length:kCntQuadTexCoords*sizeof(simd::float4) options:MTLResourceOptionCPUCacheModeDefault];
    
    if(!_verticsBuffer)
    {
        NSLog(@">> ERROR: Failed creating a vertex buffer for a quad!");
        return nil;
    }
    _verticsBuffer.label = @"quad vertices";
    _coordBuffer = [_filterDevice newBufferWithBytes:CoordBytes length:kCntQuadTexCoords*sizeof(simd::float2) options:MTLResourceOptionCPUCacheModeDefault];
    if(!_coordBuffer)
    {
        NSLog(@">> ERROR: Failed creating a 2d texture coordinate buffer!");
        return nil;
    }
    _coordBuffer.label = @"quad texcoords";
    
    if (![self preparePipelineState:pline] )
    {
        return nil;
    }
    return self;
}


- (BOOL) preparePipelineState:(METAL_PIPELINE_STATE*)filterPipelineState
{
    // get the vertex function from the library
    BOOL RET = YES;
    if (!_filterLibrary && _filterDevice)
    {
        NSError *liberr = nil;
        _filterLibrary = [_filterDevice newLibraryWithFile:@"imageQuad.metallib" error:&liberr];
        if (!_filterLibrary)
        {
            RET = NO;
        }
    }
    if (!RET)
        return RET;
    NSError *pError = nil;
    if (![filterPipelineState->vertexFuncNameStr isEqualToString:@""] && ![filterPipelineState->fragmentFuncNameStr isEqualToString:@""])
    {///just do render pipeline, no compute encoder...
        id <MTLFunction> vetexFunc = [_filterLibrary newFunctionWithName:filterPipelineState->vertexFuncNameStr];
        id <MTLFunction> fragFunc  = [_filterLibrary newFunctionWithName:filterPipelineState->fragmentFuncNameStr];
       
        renderplineStateDescriptor.depthAttachmentPixelFormat   = MTLPixelFormatInvalid;//filterPipelineState->depthPixelFormat;
        renderplineStateDescriptor.stencilAttachmentPixelFormat = filterPipelineState->stencilPixelFormat;
        renderplineStateDescriptor.colorAttachments[0].pixelFormat= MTLPixelFormatBGRA8Unorm;
        renderplineStateDescriptor.sampleCount                  = filterPipelineState->sampleCount;
        renderplineStateDescriptor.vertexFunction               = vetexFunc;
        renderplineStateDescriptor.fragmentFunction             = fragFunc;
        
        ////set alpha blending for special case
        MTLRenderPipelineColorAttachmentDescriptor *attachmentDesc = renderplineStateDescriptor.colorAttachments[0];
        
        attachmentDesc.blendingEnabled = true;

        attachmentDesc.rgbBlendOperation = MTLBlendOperationAdd;
        attachmentDesc.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        attachmentDesc.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        
        attachmentDesc.alphaBlendOperation = MTLBlendOperationAdd;
        attachmentDesc.sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
        attachmentDesc.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        
        _renderpipelineState  = [_filterDevice newRenderPipelineStateWithDescriptor:renderplineStateDescriptor error:&pError];
        
        if (!_renderpipelineState)
        {
            NSLog(@">>ERROR: Failed create renderpipeline in base filter! error is :%@",pError);
            RET = NO;
        }

    }

    if (![filterPipelineState->computeFuncNameStr isEqualToString:@"" ])
    {
        id <MTLFunction> caculateFunc   = [_filterLibrary newFunctionWithName:filterPipelineState->computeFuncNameStr];
        if (!caculateFunc)
        {
            RET = NO;
        }
        if(!RET)
            return RET;
        _caclpipelineState   = [_filterDevice newComputePipelineStateWithFunction:caculateFunc error:&pError];
        
        if(!_caclpipelineState)
        {
            NSLog(@">> ERROR: Failed acquiring compute pipeline state descriptor: %@", pError);
            
            RET = NO;
        }
        NSInteger w = _caclpipelineState.threadExecutionWidth;
        NSInteger h = _caclpipelineState.maxTotalThreadsPerThreadgroup / w;
        _threadGroupSize = MTLSizeMake(w, h, 1);
    
    }
    
    return RET;
}

-(id)getComputePipeLineFrom:(METAL_PIPELINE_STATE*)filterPipelineState{
    // get the vertex function from the library
    BOOL RET = YES;
    if (!_filterLibrary && _filterDevice)
    {
        NSError *liberr = nil;
        _filterLibrary = [_filterDevice newLibraryWithFile:@"imageQuad.metallib" error:&liberr];
        if (!_filterLibrary)
        {
            RET = NO;
        }
    }
    if (!RET)
        return Nil;
    NSError *pError = nil;
    if (![filterPipelineState->computeFuncNameStr isEqualToString:@"" ])
    {
        id <MTLFunction> caculateFunc   = [_filterLibrary newFunctionWithName:filterPipelineState->computeFuncNameStr];
        if (!caculateFunc)
        {
            RET = NO;
        }
        if(!RET)
            return Nil;
        id <MTLComputePipelineState> _cplineState   = [_filterDevice newComputePipelineStateWithFunction:caculateFunc error:&pError];
        
        if(!_cplineState)
        {
            NSLog(@">> ERROR: Failed acquiring compute pipeline state descriptor: %@", pError);
            
            RET = NO;
        }
        NSInteger w = _cplineState.threadExecutionWidth;
        NSInteger h = _cplineState.maxTotalThreadsPerThreadgroup / w;
        _threadGroupSize = MTLSizeMake(w, h, 1);
        return _cplineState;
    }
    
    return Nil;
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



- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex withFrameData:(Texture_FrameData*)pFrameData
{
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation] withAttachmentData:pFrameData];
    
    [self informTargetsAboutNewFrameAtTime:frameTime withData: pFrameData];//Just need transfer to next filter chain
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
    //colorAttachment usage is MTLTextureUsageRenderTarget;
    //using default depth and stencil dscrptor...
    
    
    return YES;
}

-(void)setInputAttachment:(id<MTLTexture>)texture  withWidth: (int)w withHeight:(int)h
{
    if ( !firstInputTexture)
    {
        firstInputTexture = [[MetalImageTexture alloc] initWithWidth:w withHeight:h withFormat:MTLPixelFormatBGRA8Unorm];
        [firstInputTexture loadTextureIntoDevice:_filterDevice];
    }

    firstInputTexture.texture = texture;
    
}
\

-(id<MTLTexture>)outputAttachment
{
    if (!outputTexture)
    {
        outputTexture =  [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight:firstInputTexture.height withFormat:MTLPixelFormatBGRA8Unorm];
    }
    return  outputTexture.texture;
    
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
            outputTexture  = [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight: firstInputTexture.height withFormat:MTLPixelFormatBGRA8Unorm];
            [outputTexture loadTextureIntoDevice:_filterDevice];
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

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime  withData:(Texture_FrameData*)pFrameData
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
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex withFrameData: pFrameData];
        }
    }
}

-(void)setInputTexture:(MetalImageTexture *)newInputTexture atIndex:(NSInteger)textureIndex
{
    if (!firstInputTexture) {
        firstInputTexture  = newInputTexture;//last filter's output texture
    }else{
        secondInputTexture = newInputTexture;
    }
}

-(CGSize)inputFrameSize
{
    CGSize sz = CGSizeMake(0, 0);
    if (firstInputTexture)
    {
        sz.width = firstInputTexture.width;
        sz.height = firstInputTexture.height;
    }
    return sz;
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
