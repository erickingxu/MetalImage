//
//  MetalImageView.m
//  MetalImage
//
//  Created by erickingxu on 2/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageView.h"
#import <simd/simd.h>

@implementation MetalImageView
{
@private
    __weak  CAMetalLayer*           _metalLayer;
    BOOL                            _layerSizeDidUpdate;
    
    id <MTLTexture>                 _depthTexture;
    id <MTLTexture>                 _stencilTexture;
    id <MTLTexture>                 _msaaTexture;
    MetalImageTexture*              inputTextureForDisplay;
    id <MTLLibrary>                 renderLibrary;
    MTLRenderPassDescriptor*        renderPassDescriptor;
    id <MTLCommandBuffer>           sharedRenderCommandBuffer;
}

@synthesize currentDrawable         = _currentDrawable;

@synthesize verticsBuffer           = _verticsBuffer;
@synthesize coordBuffer             = _coordBuffer;
@synthesize pipelineState           = _pipelineState;
@synthesize depthStencilState       = _depthStencilState;
@synthesize inputRotation           = _inputRotation;

-(void)setInputRotation:(MetalImageRotationMode)ort;
{
    inputRotation = ort;
}

/////////////////////////////////////////////////////////////////////////
+(Class)layerClass
{
    return [CAMetalLayer class];
}

-(id)initWithFrame:(CGRect)frame
{
    self =  [super initWithFrame:frame];
    if (self )
    {
        [self initCommon];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self  = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initCommon];
    }
    return self;
}

- (MTLRenderPassDescriptor *)getRenderPassDescriptor
{
    id <CAMetalDrawable> drawable = self.currentDrawable;
    if(!drawable)
    {
        NSLog(@">> ERROR: Failed to get a drawable!");
        renderPassDescriptor = nil;
    }
    else
    {
        [self setupRenderPassDescriptorForTexture: drawable.texture];
    }
    
    return renderPassDescriptor;
}

static const simd::float4 imageVertices[] = {
    { -1.0f,  -1.0f, 0.0f, 1.0f },
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    {  1.0f,   1.0f, 0.0f, 1.0f },
};

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


-(void)initCommon
{
    self.opaque                     = YES;
    self.backgroundColor            = nil;
    _metalLayer                     = (CAMetalLayer*) self.layer;
    _device                         = [MetalImageCmdQueue getGlobalDevice];
    _metalLayer.device              = _device;
    _metalLayer.pixelFormat         = MTLPixelFormatBGRA8Unorm;
    _metalLayer.framebufferOnly     = YES;
    renderLibrary                   = [_device newDefaultLibrary];
    self.depthPixelFormat           = MTLPixelFormatDepth32Float;
    self.stencilPixelFormat         = MTLPixelFormatInvalid;
    self.sampleCount                = 1;
    sharedRenderCommandBuffer       = nil;
    inputRotation                   = kMetalImageFlipHorizonal;
    //set output texture and draw reslut to it
    _verticsBuffer = [_device newBufferWithBytes:imageVertices length:6*sizeof(simd::float4) options:MTLResourceOptionCPUCacheModeDefault];
    
    if(!_verticsBuffer)
    {
        NSLog(@">> ERROR: Failed creating a vertex buffer for a quad!");
        return ;
    }
    _verticsBuffer.label = @"quad vertices";
    _coordBuffer = [_device newBufferWithBytes:[[self class] textureCoordinatesForRotation: inputRotation] length:6*sizeof(simd::float2) options:MTLResourceOptionCPUCacheModeDefault];
    if(!_coordBuffer)
    {
        NSLog(@">> ERROR: Failed creating a 2d texture coordinate buffer!");
        return;
    }
    _coordBuffer.label = @"quad texcoords";
    
    [self prepareRenderPipeline];
    [self prepareRenderDepthStencilState];
}
//////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)prepareRenderPipeline
{
    // get the vertex function from the library
    if (!renderLibrary && _device)
    {
        NSError *liberr = nil;
        renderLibrary = [_device newLibraryWithFile:@"imageQuad.metallib" error:&liberr];
    }
    
    id <MTLFunction> vertexProgram   = [renderLibrary newFunctionWithName:@"imageQuadVertex"];
    // get the fragment function from the library
    id <MTLFunction> fragmentProgram = [renderLibrary newFunctionWithName:@"imageQuadFragment"];
    if (!vertexProgram || !fragmentProgram)
    {
        return NO;
    }
    //  create a pipeline state for the quad
    MTLRenderPipelineDescriptor *pQuadPipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    pQuadPipelineStateDescriptor.depthAttachmentPixelFormat      = MTLPixelFormatDepth32Float;
    pQuadPipelineStateDescriptor.stencilAttachmentPixelFormat    = MTLPixelFormatInvalid;
    pQuadPipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pQuadPipelineStateDescriptor.sampleCount                     = 1;
    pQuadPipelineStateDescriptor.vertexFunction                  = vertexProgram;
    pQuadPipelineStateDescriptor.fragmentFunction                = fragmentProgram;
    
    NSError *pError = nil;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pQuadPipelineStateDescriptor error:&pError];
    if(!_pipelineState)
    {
        NSLog(@">> ERROR: Failed acquiring pipeline state descriptor: %@", pError);
        
        return NO;
    } // if
    
    return YES;
}

- (BOOL) prepareRenderDepthStencilState
{
    MTLDepthStencilDescriptor *pDepthStateDesc = [MTLDepthStencilDescriptor new];
    
    if(!pDepthStateDesc)
    {
        NSLog(@">> ERROR: Failed creating a depth stencil descriptor!");
        
        return NO;
    } // if
    
    pDepthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    pDepthStateDesc.depthWriteEnabled    = YES;
    
    _depthStencilState = [_device newDepthStencilStateWithDescriptor:pDepthStateDesc];
    
    if(!_depthStencilState)
    {
        return NO;
    } // if
    
    return YES;
}


//////draw filter result to view for assigned texture
-(void)setupRenderPassDescriptorForTexture:(id <MTLTexture>)textureForDraw
{
    if (nil == renderPassDescriptor)//could be resue....
    {
        renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
    }
    MTLRenderPassColorAttachmentDescriptor    *colorAttachment  = renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture         = textureForDraw;
    colorAttachment.loadAction      = MTLLoadActionClear;
    colorAttachment.clearColor      = MTLClearColorMake(0.0, 0.0, 1.0, 0.8);//black
    if (_sampleCount > 1)
    {
        BOOL doUpdate               = (_msaaTexture.width != textureForDraw.width) || (_msaaTexture.height != textureForDraw.height) || (_msaaTexture.sampleCount != _sampleCount);
        if (!_msaaTexture || (_msaaTexture && doUpdate))
        {
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:textureForDraw.width height: textureForDraw.height mipmapped:NO];
            desc.textureType        = MTLTextureType2DMultisample;
            desc.sampleCount        = _sampleCount;
            _msaaTexture            = [_device newTextureWithDescriptor:desc];//load texture to gpu
        }
        colorAttachment.texture     = _msaaTexture;
        colorAttachment.resolveTexture = textureForDraw;
        colorAttachment.storeAction = MTLStoreActionMultisampleResolve;
    }
    else
    {
        colorAttachment.storeAction = MTLStoreActionStore;
    }
    
    //create depth and stencil attachments
    if (_depthPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate =     ( _depthTexture.width != textureForDraw.width)||( _depthTexture.height != textureForDraw.height )||( _depthTexture.sampleCount != _sampleCount   );
        
        if(!_depthTexture || doUpdate)
        {
            //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
            //  Then allocate one of the proper size
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _depthPixelFormat
                                                                                            width: textureForDraw.width
                                                                                           height: textureForDraw.height
                                                                                        mipmapped: NO];
            
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            
            _depthTexture = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassDepthAttachmentDescriptor *depthAttachment = renderPassDescriptor.depthAttachment;
            depthAttachment.texture = _depthTexture;
            depthAttachment.loadAction = MTLLoadActionClear;
            depthAttachment.storeAction = MTLStoreActionDontCare;
            depthAttachment.clearDepth = 1.0;
        }
    }
    if(_stencilPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate = ( _stencilTexture.width != textureForDraw.width )||( _stencilTexture.height != textureForDraw.height )
        ||  ( _stencilTexture.sampleCount != _sampleCount   );
        
        if(!_stencilTexture || doUpdate)
        {
            //  If we need a stencil texture and don't have one, or if the depth texture we have is the wrong size
            //  Then allocate one of the proper size
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _stencilPixelFormat
                                                                                            width: textureForDraw.width
                                                                                           height: textureForDraw.height
                                                                                        mipmapped: NO];
            
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            
            _stencilTexture = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassStencilAttachmentDescriptor* stencilAttachment = renderPassDescriptor.stencilAttachment;
            stencilAttachment.texture = _stencilTexture;
            stencilAttachment.loadAction = MTLLoadActionClear;
            stencilAttachment.storeAction = MTLStoreActionDontCare;
            stencilAttachment.clearStencil = 0;
        }
    } //stencil
}

- (id <CAMetalDrawable>)currentDrawable
{
    if (_currentDrawable == nil)
        _currentDrawable = [_metalLayer nextDrawable];
    
    return _currentDrawable;
}

#pragma mark -
#pragma mark GPUInput protocol
-(id <MTLCommandBuffer>) getNewCommandBuffer
{
    return [MetalImageCmdQueue getNewCommandBuffer];
}



- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    
@autoreleasepool
{
        // handle display changes here
        if(_layerSizeDidUpdate)
        {
            // set the metal layer to the drawable size in case orientation or size changes
            CGSize drawableSize = self.bounds.size;
            drawableSize.width  *= self.contentScaleFactor;
            drawableSize.height *= self.contentScaleFactor;
            if (drawableSize.width == 0 || drawableSize.height == 0) {
                drawableSize.width = 1;
                drawableSize.height = 1;
            }
            _metalLayer.drawableSize = drawableSize;
            _layerSizeDidUpdate = NO;
        }
        
    
    dispatch_semaphore_wait([MetalImageCmdQueue getSemaphore], DISPATCH_TIME_FOREVER);
   
    // create a render command encoder so we can render into something
    MTLRenderPassDescriptor *renderPassDescriptor1 = [self getRenderPassDescriptor];
    if (renderPassDescriptor1 && sharedRenderCommandBuffer)
    {
        // Get a render encoder
        id <MTLRenderCommandEncoder>  renderEncoder = [sharedRenderCommandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor1];
        if([self renderWithEncoder:renderEncoder])
        {
            // Present and commit the command buffer
            [sharedRenderCommandBuffer presentDrawable:self.currentDrawable];
        }
        else
        {
            [renderEncoder endEncoding];
            return;
        }
    }
    
//    Dispatch the command buffer

    __block dispatch_semaphore_t dispatchSemaphore = [MetalImageCmdQueue getSemaphore];
    
    [sharedRenderCommandBuffer addCompletedHandler:^(id <MTLCommandBuffer> cmdb){
        NSLog(@"****************fresh another commderbuffer for display!!!********************");
        dispatch_semaphore_signal(dispatchSemaphore);
    }];
    
    
    [sharedRenderCommandBuffer commit];
    // do not retain current drawable beyond the frame.
    // There should be no strong references to this object outside of this view class
    _currentDrawable    = nil;
 }
    
}

-(BOOL)renderWithEncoder:(id <MTLRenderCommandEncoder>) rEncoder
{
    if (!inputTextureForDisplay)
    {
        return NO;
    }
    // Encode into a renderer
    [rEncoder pushDebugGroup:@"encodequad"];
    [rEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [rEncoder setDepthStencilState:_depthStencilState];
    [rEncoder setRenderPipelineState:_pipelineState];
    _coordBuffer = [_device newBufferWithBytes:[[self class] textureCoordinatesForRotation: inputRotation] length:6*sizeof(simd::float2) options:MTLResourceOptionCPUCacheModeDefault];
    [rEncoder setFragmentTexture: inputTextureForDisplay.texture atIndex:0];
    [rEncoder setVertexBuffer:_verticsBuffer  offset:0  atIndex: 0 ];
    [rEncoder setVertexBuffer:_coordBuffer    offset:0  atIndex: 1];
    
    
    // tell the render context we want to draw our primitives
    [rEncoder drawPrimitives: MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:1];
    
    [rEncoder endEncoding];
    [rEncoder popDebugGroup];
    return YES;
}
- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

-(void)setInputCommandBuffer:(id <MTLCommandBuffer>)cmdBuffer  atIndex:(NSInteger)index;
{
//    if (self)
//    {
        sharedRenderCommandBuffer = cmdBuffer;
//    }
    
//    sharedRenderCommandBuffer = nil;
    
}


- (void)setInputTexture:(MetalImageTexture *)newInputTexture atIndex:(NSInteger)textureIndex;
{
    inputTextureForDisplay = newInputTexture;
//    UIImage* image = newInputTexture.img;
//    ///do something for texture load
//    inputTextureForDisplay = [[MetalImageTexture alloc] initWithImage:image.CGImage andWithMetalDevice:_device];
    //[inputTextureForDisplay lock];
}

- (void)setInputRotation:(MetalImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = newInputRotation;
}

- (void)releaseTextures
{
    _depthTexture                   = nil;
    _stencilTexture                 = nil;
    _msaaTexture                    = nil;
}

-(void)didMoveToWindow
{
    self.contentScaleFactor         = self.window.screen.nativeScale;
}
- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:contentScaleFactor];
    
    _layerSizeDidUpdate = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _layerSizeDidUpdate = YES;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex
{
    newSize.width = 0;
}


@end
