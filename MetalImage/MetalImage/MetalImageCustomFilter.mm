//
//  MetalImageCustomFilter.m
//  MetalImage
//
//  Created by xuqing on 8/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImageCustomFilter.h"
#import "AssertLoader/MetalImageTexture.h"
#import <simd/simd.h>
#import "MetalImageCmdQueue.h"
///////////////////////////////////////////////////////////////////////////////////
static const uint32_t kCntQuadTexCoords = 6;
static const uint32_t kSzQuadTexCoords  = kCntQuadTexCoords * sizeof(simd::float2);

static const uint32_t kCntQuadVertices  = kCntQuadTexCoords;
static const uint32_t kSzQuadVertices   = kCntQuadVertices * sizeof(simd::float4);

static const simd::float4 kQuadVertices[kCntQuadVertices] =
{
    { -1.0f,  -1.0f, 0.0f, 1.0f },
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    {  1.0f,   1.0f, 0.0f, 1.0f }
};

static const simd::float2 noRotationTextureCoordinates[kCntQuadTexCoords] = {
    {0.0f, 0.0f},
    {1.0f, 0.0f},
    {0.0f, 1.0f},

    {1.0f, 0.0f},
    {0.0f, 1.0f},
    {1.0f, 1.0f}
};

static const simd::float2 rotateLeftTextureCoordinates[kCntQuadTexCoords] = {
    {1.0f, 0.0f},
    {1.0f, 1.0f},
    {0.0f, 0.0f},
    
    {1.0f, 1.0f},
    {0.0f, 0.0f},
    {0.0f, 1.0f},
};

static const simd::float2 rotateRightTextureCoordinates[kCntQuadTexCoords] = {
    {0.0f, 1.0f},
    {0.0f, 0.0f},
    {1.0f, 1.0f},
    
    {0.0f, 0.0f},
    {1.0f, 1.0f},
    {1.0f, 0.0f},
};

static const simd::float2 verticalFlipTextureCoordinates[kCntQuadTexCoords] = {
    {0.0f, 1.0f},
    {1.0f, 1.0f},
    {0.0f, 0.0f},
    
    {1.0f,  1.0f},
    {0.0f,  0.0f},
    {1.0f,  0.0f},
};

static const simd::float2 horizontalFlipTextureCoordinates[kCntQuadTexCoords] = {
    {1.0f,  0.0f},
    {0.0f,  0.0f},
    {1.0f,  1.0f},
    
    {0.0f,  0.0f},
    {1.0f,  1.0f},
    {0.0f,  1.0f},
};

static const simd::float2 rotateRightVerticalFlipTextureCoordinates[kCntQuadTexCoords] = {
    {0.0f, 0.0f},
    {0.0f, 1.0f},
    {1.0f, 0.0f},
    
    {0.0f, 1.0f},
    {1.0f, 0.0f},
    {1.0f, 1.0f},
};

static const simd::float2 rotateRightHorizontalFlipTextureCoordinates[kCntQuadTexCoords] = {
    {1.0f, 1.0f},
    {1.0f, 0.0f},
    {0.0f, 1.0f},
    
    {1.0f, 0.0f},
    {0.0f, 1.0f},
    {0.0f, 0.0f},
};

static const simd::float2 rotate180TextureCoordinates[kCntQuadTexCoords] = {
    {1.0f, 1.0f},
    {0.0f, 1.0f},
    {1.0f, 0.0f},
    
    {0.0f, 1.0f},
    {1.0f, 0.0f},
    {0.0f, 0.0f},
};

/////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MetalImageCustomFilter()
{
    id <MTLDevice>              _imgfilterDevice;
    id <MTLBuffer>              _verticsBuffer;
    id <MTLBuffer>              _coordBuffer;
    MetalImageTexture*          _inputTextrue;
    MetalImageTexture*          _outputTextrue;
    
    id <MTLRenderPipelineState> _pipelineState;

    id <MTLDepthStencilState>   _depthStencilState;
    
    
    NSString*                   _vertexShaderName;
    NSString*                   _fragmentShaderName;
    id <MTLLibrary>             _filterLibrary;
    BOOL                        _bFBOOnly;//for view layer, yes is to draw, no is for compute
    //id <MTLCommandBuffer>       _commandBuffer;

}

@end

@implementation MetalImageCustomFilter
@synthesize depthPixelFormat = _depthPixelFormat;
@synthesize stencilPixelFormat = _stencilPixelFormat;

-(id)init
{

    if (!(self = [super init]))
    {
        return nil;
    }
    id <MTLDevice> fDevice = [MetalImageCmdQueue getGlobalDevice];
    [self loadWithDevice:fDevice];
    return self;
}

-(void)loadWithDevice:(id <MTLDevice>) filterDevice
{
    if (filterDevice)
    {
        _imgfilterDevice    = filterDevice;//keep one for use
        _filterLibrary      = [_imgfilterDevice newDefaultLibrary];
        _depthPixelFormat   = MTLPixelFormatDepth32Float;
        _stencilPixelFormat = MTLPixelFormatInvalid;
        _bFBOOnly           = NO;
        _inputTextrue       = nil;
        _outputTextrue      = nil;
    }
}
// load all assets before triggering rendering
- (BOOL)configure:(METAL_FILTER_PIPELINE_STATE*)plinestate
{
    if (!self )
    {
        return NO;
    }
    if ([self loadViewBufferwithOrientation:plinestate->orient])
    {
        if ( [(plinestate->computeFuncNameStr) isEqualToString:@""] && !([(plinestate->textureImagePath) isEqualToString:@""]))
        {
            [self prepareTexture2DfromResource:plinestate->textureImagePath];
        }
        [self prepareViewPipelineState:plinestate];
        [self prepareViewDepthStencilState];
        return YES;
    }
    return NO;
}

-(id <MTLDevice> ) getFilterDevice
{
    return _imgfilterDevice;
}

-(id <MTLLibrary> ) getShaderLibrary
{
    return _filterLibrary;
}

-(dispatch_semaphore_t)getAvialiableDrawableSem
{
    return [MetalImageCmdQueue getSemaphore];
}

-(id <MTLCommandBuffer>) getNewCommandBuffer
{
    return [MetalImageCmdQueue getNewCommandBuffer];
}

-(void)filterRender:(MetalImageCustomView*)metalView withDrawableTexture:(MetalImageTexture*)drawableTexture inCommandBuffer:(id <MTLCommandBuffer>)cmdBuffer;
{
    //dispatch_semaphore_wait([MetalImageCmdQueue getSemaphore], DISPATCH_TIME_FOREVER);
    if (!cmdBuffer)
    {
        cmdBuffer =  [self getNewCommandBuffer];
    }
    // create a render command encoder so we can render into something
    MTLRenderPassDescriptor *renderPassDescriptor = metalView.renderPassDescriptor;
    if (renderPassDescriptor && cmdBuffer)
    {
        // Get a render encoder
        id <MTLRenderCommandEncoder>  renderEncoder = [cmdBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        // Encode into a renderer
        [self loadMetalsourcetoEncoder:renderEncoder withInputTexture:drawableTexture];
        
        // Present and commit the command buffer
        [cmdBuffer presentDrawable:metalView.currentDrawable];
       
    }
    
    //Dispatch the command buffer
//    __block dispatch_semaphore_t dispatchSemaphore = [MetalImageCmdQueue getSemaphore];
//    
//    [cmdBuffer addCompletedHandler:^(id <MTLCommandBuffer> cmdb){
//        NSLog(@"****************Wooo, li ge fuck world!!!********************");
//        dispatch_semaphore_signal(dispatchSemaphore);
//    }];
    
    [cmdBuffer commit];
        [cmdBuffer waitUntilCompleted];
}

- (BOOL) loadMetalsourcetoEncoder:(id <MTLRenderCommandEncoder>)renderEncoder  withInputTexture:(MetalImageTexture*)inputDrawTexture
{
    if (!_depthStencilState || !_pipelineState || !_verticsBuffer || !_coordBuffer)
    {
        return NO;
    }
    // set context state with the render encoder
    [renderEncoder pushDebugGroup:@"encode quad"];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setDepthStencilState:_depthStencilState];
    if (inputDrawTexture)
    {
        [renderEncoder setFragmentTexture: inputDrawTexture.texture atIndex:0];
    }
    else
    {
        [renderEncoder setFragmentTexture: _inputTextrue.texture atIndex:0];
    }
    //*****************************************************************//
    //[renderEncoder setFragmentTexture: _outputTextrue.texture atIndex:1];
    //*****************************************************************//
    // Encode quad vertex and texture coordinate buffers
    [renderEncoder setVertexBuffer:_verticsBuffer  offset:0  atIndex: 0 ];
    [renderEncoder setVertexBuffer:_coordBuffer offset:0  atIndex: 1];

    [renderEncoder setRenderPipelineState:_pipelineState];

    // tell the render context we want to draw our primitiv the listening all noes
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:1];
    
    [renderEncoder endEncoding];
    [renderEncoder popDebugGroup];
    return YES;
} // _encode


- (BOOL) prepareViewPipelineState:(METAL_FILTER_PIPELINE_STATE*)filterPipelineState
{
    // get the vertex function from the library
    if (!_filterLibrary && _imgfilterDevice)
    {
         NSError *liberr = nil;
        _filterLibrary = [_imgfilterDevice newLibraryWithFile:@"imageQuad.metallib" error:&liberr];
    }

    id <MTLFunction> vertexProgram   = [_filterLibrary newFunctionWithName:filterPipelineState->vertexFuncNameStr];
    // get the fragment function from the library
    id <MTLFunction> fragmentProgram = [_filterLibrary newFunctionWithName:filterPipelineState->fragmentFuncNameStr];
    
    //  create a pipeline state for the quad
    MTLRenderPipelineDescriptor *pQuadPipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    pQuadPipelineStateDescriptor.depthAttachmentPixelFormat      = filterPipelineState->depthPixelFormat;
    pQuadPipelineStateDescriptor.stencilAttachmentPixelFormat    = filterPipelineState->stencilPixelFormat;
    pQuadPipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pQuadPipelineStateDescriptor.sampleCount                     = filterPipelineState->sampleCount;
    pQuadPipelineStateDescriptor.vertexFunction                  = vertexProgram;
    pQuadPipelineStateDescriptor.fragmentFunction                = fragmentProgram;
    
    NSError *pError = nil;
    _pipelineState = [_imgfilterDevice newRenderPipelineStateWithDescriptor:pQuadPipelineStateDescriptor error:&pError];
    if(!_pipelineState)
    {
        NSLog(@">> ERROR: Failed acquiring pipeline state descriptor: %@", pError);
        
        return NO;
    } // if
    
    return YES;
} // preparePipelineState

- (BOOL) prepareViewDepthStencilState
{
    MTLDepthStencilDescriptor *pDepthStateDesc = [MTLDepthStencilDescriptor new];
    
    if(!pDepthStateDesc)
    {
        NSLog(@">> ERROR: Failed creating a depth stencil descriptor!");
        
        return NO;
    } // if
    
    pDepthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    pDepthStateDesc.depthWriteEnabled    = YES;
    
    _depthStencilState = [_imgfilterDevice newDepthStencilStateWithDescriptor:pDepthStateDesc];
    
    if(!_depthStencilState)
    {
        return NO;
    } // if
    
    return YES;
} // prepareDepthStencilState

-(BOOL)prepareTexture2DfromResource:(NSString*)sourcePath
{
    if (!sourcePath)
    {
        return NO;
        
    }
    _inputTextrue = [[MetalImageTexture alloc] initWithResource:sourcePath];
    [_inputTextrue loadTextureIntoDevice:_imgfilterDevice];
    
    MTLTextureDescriptor *pTexDescp = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:_inputTextrue.width height:_inputTextrue.height mipmapped:NO];
    
    _outputTextrue = [_imgfilterDevice newTextureWithDescriptor:pTexDescp];
    if (!_outputTextrue)
    {
        NSLog(@"Error: Can not create 2d texture for filter's output!!!");
        return NO;
    }
    return YES;
}

-(BOOL)loadViewBufferwithOrientation:(MetalOrientation)orient
{
    _verticsBuffer = [_imgfilterDevice newBufferWithBytes:kQuadVertices
                                         length:kSzQuadVertices
                                        options:MTLResourceOptionCPUCacheModeDefault];
    
    if(!_verticsBuffer)
    {
        NSLog(@">> ERROR: Failed creating a vertex buffer for a quad!");
        
        return NO;
    } // if
    _verticsBuffer.label = @"quad vertices";
    switch (orient)
    {
        case MetalOrientationUnknown:
        {
            _coordBuffer = [_imgfilterDevice newBufferWithBytes:noRotationTextureCoordinates
                                                         length:kSzQuadTexCoords
                                                        options:MTLResourceOptionCPUCacheModeDefault];
        }
            break;
        case MetalOrientationPortrait:
        {
            _coordBuffer = [_imgfilterDevice newBufferWithBytes:rotateLeftTextureCoordinates
                                                         length:kSzQuadTexCoords
                                                        options:MTLResourceOptionCPUCacheModeDefault];
        }
            break;
        case MetalOrientationLandscapeLeft:
        {
            _coordBuffer = [_imgfilterDevice newBufferWithBytes:rotateRightVerticalFlipTextureCoordinates
                                                         length:kSzQuadTexCoords
                                                        options:MTLResourceOptionCPUCacheModeDefault];
        }
            break;
        case MetalOrientationLandscapeRight:
        {
            _coordBuffer = [_imgfilterDevice newBufferWithBytes:rotateRightHorizontalFlipTextureCoordinates
                                                         length:kSzQuadTexCoords
                                                        options:MTLResourceOptionCPUCacheModeDefault];
        }
            break;
        default:
        {
            _coordBuffer = [_imgfilterDevice newBufferWithBytes:noRotationTextureCoordinates
                                                         length:kSzQuadTexCoords
                                                        options:MTLResourceOptionCPUCacheModeDefault];
        }
            break;
    }
    
    
    if(!_coordBuffer)
    {
        NSLog(@">> ERROR: Failed creating a 2d texture coordinate buffer!");
        
        return NO;
    } // if
    _coordBuffer.label = @"quad texcoords";
    return YES;
}



- (void)initializePipelineStateWithVertexShader:(NSString*)vertexShaderName fragmentShader:(NSString*)fragmentShaderName;
{
    
}

- (instancetype)initWithvertexShader:(NSString*)vertexShaderName fragmentShader:(NSString*)fragmentShaderName texture:(MetalImageTexture*)texture
{
    return self;
}

@end
