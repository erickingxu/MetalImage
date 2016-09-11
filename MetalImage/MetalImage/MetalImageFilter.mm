//
//  MetalImageFilter.m
//  MetalImage
//
//  Created by xuqing on 1/8/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImageFilter.h"
#import <simd/simd.h>

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
    peline.computeFuncNameStr =  @"basePass";
    
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
    if (![self prepareComputePipelineState:pline] )
    {
        return nil;
    }
    return self;
}


- (BOOL) prepareComputePipelineState:(METAL_PIPELINE_STATE*)filterPipelineState
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

    if ([filterPipelineState->computeFuncNameStr isEqualToString:@""])
    {
        return NO;
    }
    id <MTLFunction> caculateFunc   = [_filterLibrary newFunctionWithName:filterPipelineState->computeFuncNameStr];
    NSError *pError = nil;
    _caclpipelineState   = [_filterDevice newComputePipelineStateWithFunction:caculateFunc error:&pError];
    
    if(!_caclpipelineState)
    {
        NSLog(@">> ERROR: Failed acquiring compute pipeline state descriptor: %@", pError);
        
        return NO;
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
-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    
    if (commandBuffer && _caclpipelineState)
    {
        id <MTLComputeCommandEncoder>  cmputEncoder = [commandBuffer computeCommandEncoder];
        if (cmputEncoder)
        {
            [cmputEncoder  setComputePipelineState:_caclpipelineState];
            [cmputEncoder setTexture: firstInputTexture.texture atIndex:0];
            [cmputEncoder setTexture: outputTexture.texture atIndex:1];
            [cmputEncoder dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder endEncoding];
            
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
    //outputTexture  = firstInputTexture;
    //set output texture and draw reslut to it
    _verticsBuffer = [_filterDevice newBufferWithBytes:vertices length:sizeof(simd::float2) options:MTLResourceOptionCPUCacheModeDefault];
    
    if(!_verticsBuffer)
    {
        NSLog(@">> ERROR: Failed creating a vertex buffer for a quad!");
        return ;
    }
    _verticsBuffer.label = @"quad vertices";
    _coordBuffer = [_filterDevice newBufferWithBytes:textureCoordinates length:sizeof(simd::float2) options:MTLResourceOptionCPUCacheModeDefault];
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
    return CGSizeMake(0, 0);///???????
}
- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}
@end
