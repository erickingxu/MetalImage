//
//  MetalImageVideo.m
//  MetalImage
//
//  Created by xuqing on 26/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImageVideo.h"
#import <UIKit/UIKit.h>
#import <simd/simd.h>
#import <CoreVideo/CVMetalTextureCache.h>
//////////////////////////////////////////GLOBLE AND STATIC VARIABLES//////////////////////////////////////

static const long kMAXBUFFERBYTESPERFRAME       =  1024*1024;

///////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MetalImageVideo
{
    id <MTLComputePipelineState>    _videopipelineState;
    // Compute kernel parameters
    MTLSize                         _threadGroupSize;
    MTLSize                         _threadGroupCount;
    
    id <MTLDepthStencilState>       _videodepthStencilState;
    id <MTLDevice>                  _videofilterDevice;
    id <MTLLibrary>                 _videoLibrary;
    MetalImageTexture*              _sourceTexture;

    //////////////Video texture/////////////////////////
    AVCaptureSession*               _captureSession;
    CVMetalTextureCacheRef          _videoTextureCache;
    MetalImageTexture*              _videoTexture;
    MetalImageTexture*              _videoOuptTexture;
    
    int                             _videoWidth;
    int                             _videoHeight;
}

-(id)init
{
    
    if (!(self = [super init]))
    {
        return nil;
    }
    _videoWidth =  _videoHeight = 0;
    _videopipelineState = nil;
    _videoLibrary       = [self getShaderLibrary];
    _videofilterDevice  = [self getFilterDevice];
    [self setupVideo];
    return self;
}

- (BOOL)configure:(METAL_FILTER_PIPELINE_STATE*)plinestate
{
    if ([super configure:plinestate] )
    {
        [self prepareVideoPipelineState:plinestate];
        [self prepareVideoDepthStencilState];
        
        return YES;
    }
    return NO;
}

-(void)setupVideo
{
    CVMetalTextureCacheFlush(_videoTextureCache, 0);
    CVReturn textCachRes = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, _videofilterDevice, NULL, &_videoTextureCache);
    if(textCachRes)
    {
        NSLog(@"ERROR: Can not create a video texture cache!!! ");
        assert(0);
    }
    //init a video capture session
    _captureSession     = [[AVCaptureSession alloc] init];
    if (!_captureSession)
    {
        NSLog(@"Can not create a video capture session!!!");
        assert(0);
    }
    [_captureSession beginConfiguration];
    [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    AVCaptureDevice *videoCaptureDevice  = nil;
    NSArray* deviceArr = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice* device  in deviceArr)
    {
        if ([device position] == AVCaptureDevicePositionFront)
        {
            videoCaptureDevice  = device;
        }
    }
    if (videoCaptureDevice == nil)
    {
        videoCaptureDevice     = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    if (videoCaptureDevice == nil)
    {
        NSLog(@">>>>>>>>>>Error: Can not create a video capture device!!!");
        assert(0);
    }
    //create video input with owned device
    NSError  *videoErr = nil;
    AVCaptureDeviceInput   *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&videoErr];
    if (videoErr)
    {
        NSLog(@">> ERROR: Couldnt create AVCaptureDeviceInput");
        assert(0);
    }
    
    [_captureSession addInput:videoInput];
    ///create video output for process image
    AVCaptureVideoDataOutput * dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    // Set the color space.
    [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                             forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    // Set dispatch to be on the main thread to create the texture in memory and allow Metal to use it for rendering
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [_captureSession addOutput:dataOutput];
    [_captureSession commitConfiguration];
    
    // this will trigger capture on its own queue
    [_captureSession startRunning];
}

///samplebuffer delegate func
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVReturn error;
    
    CVImageBufferRef sourceImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(sourceImageBuffer);
    size_t height = CVPixelBufferGetHeight(sourceImageBuffer);
    //    {
    //        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:sourceImageBuffer];
    //        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    //        CGImageRef videoImage = [temporaryContext
    //                                 createCGImage:ciImage
    //                                 fromRect:CGRectMake(0, 0,
    //                                                     CVPixelBufferGetWidth(sourceImageBuffer),
    //                                                     CVPixelBufferGetHeight(sourceImageBuffer))];
    //
    //        UIImage *image = [[UIImage alloc] initWithCGImage:videoImage];
    //        CGImageRelease(videoImage);
    //    }
    CVMetalTextureRef textureRef;
    error = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, sourceImageBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &textureRef);
    
    if (error)
    {
        NSLog(@">> ERROR: Couldnt create texture from image");
        assert(0);
    }
    _videoTexture = [[MetalImageTexture alloc] initWithWidth:(uint32_t)width withHeight:(uint32_t)height];
    _videoTexture.texture = CVMetalTextureGetTexture(textureRef);
    
    if (!_videoTexture)
    {
        NSLog(@">> ERROR: Couldn't get texture from texture ref");
        assert(0);
    }
    //update kernel width and height
    NSUInteger nthreadWidthSteps  = (_videoTexture.width + _threadGroupSize.width - 1) / _threadGroupSize.width;
    NSUInteger nthreadHeightSteps = (_videoTexture.height+ _threadGroupSize.height - 1)/ _threadGroupSize.height;
    
    _threadGroupCount             = MTLSizeMake(nthreadWidthSteps, nthreadHeightSteps, 1);
    
    CVBufferRelease(textureRef);

}

-(void)filterRender:(MetalImageCustomView*)metalView withDrawableTexture:(MetalImageTexture *)drawableTexture inCommandBuffer:(id<MTLCommandBuffer>)cmdBuffer
{
    //dispatch_semaphore_wait(_drawableSemaphore, DISPATCH_TIME_FOREVER);
    id <MTLCommandBuffer>  videocmdBuffer   = [self getNewCommandBuffer];
    _videoOuptTexture                       = [[MetalImageTexture alloc] init];//no need to allocate new memory from device
    
    [self caculateVideowithCmdBuffer:videocmdBuffer];
    // create a render command encoder so we can render something on it
    if (videocmdBuffer && _videoTexture)
    {
        [super filterRender:metalView withDrawableTexture:_videoOuptTexture inCommandBuffer:videocmdBuffer];
    }
    
}


-(void)caculateVideowithCmdBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    
    if (commandBuffer && _videopipelineState)
    {
        id <MTLComputeCommandEncoder>  gaussEncoder = [commandBuffer computeCommandEncoder];
        
        if (gaussEncoder)
        {
            [gaussEncoder setComputePipelineState:_videopipelineState];
            [gaussEncoder setTexture:_videoTexture.texture atIndex:0];
            [gaussEncoder setTexture:_videoOuptTexture.texture atIndex:1];
            [gaussEncoder dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [gaussEncoder endEncoding];
            
        }
        else
        {
            _videoOuptTexture                       = _videoTexture;
        }
    }
    else
    {
        _videoOuptTexture                       = _videoTexture;
    }
}


- (BOOL) prepareVideoPipelineState:(METAL_FILTER_PIPELINE_STATE*)filterPipelineState
{
    // get the vertex function from the library
    if (!_videoLibrary && _videofilterDevice)
    {
        NSError *liberr = nil;
        _videoLibrary = [_videofilterDevice newLibraryWithFile:@"imageVideo.metallib" error:&liberr];
    }
    
    id <MTLFunction> videoFunc   = [_videoLibrary newFunctionWithName:filterPipelineState->computeFuncNameStr];
    if (!videoFunc)
    {
        NSLog(@"ERRO:Create a new func for video FAIL....");
        return  NO;
    }
    NSError *pError = nil;
    _videopipelineState = [_videofilterDevice newComputePipelineStateWithFunction:videoFunc error:&pError];
    if(!_videopipelineState)
    {
        NSLog(@">> ERROR: Failed acquiring pipeline state descriptor: %@", pError);
        
        return NO;
    } // if
    _threadGroupSize = MTLSizeMake(16, 16, 1);
//    _sourceTexture = [[MetalImageTexture alloc] initWithResource:filterPipelineState->textureImagePath];
//    [_sourceTexture loadTextureIntoDevice:_videofilterDevice];
    
    return YES;
}

- (BOOL) prepareVideoDepthStencilState
{
    MTLDepthStencilDescriptor *pDepthStateDesc = [MTLDepthStencilDescriptor new];
    
    if(!pDepthStateDesc)
    {
        NSLog(@">> ERROR: Failed creating a depth stencil descriptor!");
        
        return NO;
    } // if
    
    pDepthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    pDepthStateDesc.depthWriteEnabled    = YES;
    
    _videodepthStencilState = [_videofilterDevice newDepthStencilStateWithDescriptor:pDepthStateDesc];
    
    if(!_videodepthStencilState)
    {
        return NO;
    } // if
    
    return YES;
}
@end
