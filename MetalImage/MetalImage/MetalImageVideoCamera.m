//
//  MetalImageVideoCamera.m
//  MetalImage
//
//  Created by erickingxu on 10/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageVideoCamera.h"
#import <UIKit/UIKit.h>
#import <simd/simd.h>
#import <CoreVideo/CVMetalTextureCache.h>
/////////////////GLOBLE AND STATIC VARIABLES//////////////////////////

@implementation MetalImageVideoCamera
{
    //////////////Video texture/////////////////////////
    AVCaptureSession*               _captureSession;
    
    id <MTLDevice>                  videoDevice;
    CVMetalTextureCacheRef          videoTextureCache;
    
    int                             videoWidth;
    int                             videoHeight;
    MetalImageCmdQueue*             videoCommandQueue;
    MetalImageRotationMode          inputRotation;
    
}

////////////////////////////////////////////////////////////////////////
-(id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    videoWidth =  videoHeight = 0;
    videoDevice = [MetalImageCmdQueue getGlobalDevice];
    videoTextureCache = nil;
  
    [self setupVideo];
    
    return self;
}


-(void)setupVideo
{
    CVMetalTextureCacheFlush(videoTextureCache, 0);
    CVReturn textCachRes = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, videoDevice, NULL, &videoTextureCache);
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
   
    CVMetalTextureRef textureRef;
    error = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, sourceImageBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &textureRef);
    
    if (error)
    {
        NSLog(@">> ERROR: Couldnt create texture from image");
        assert(0);
    }
    outputTexture = [[MetalImageTexture alloc] initWithWidth:(uint32_t)width withHeight:(uint32_t)height];
    outputTexture.texture = CVMetalTextureGetTexture(textureRef);
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [self fireOn];
    
    if (!outputTexture)
    {
        NSLog(@">> ERROR: Couldn't get texture from texture ref");
        assert(0);
    }
    [self videoSampleBufferProcessing:currentTime];
    
    CVBufferRelease(textureRef);
    
}

-(void)videoSampleBufferProcessing:(CMTime)frameTime
{
    for (id<MetalImageInput> currentTarget in targets)
    {
        NSInteger indexOfObject = [targets indexOfObject:currentTarget];
        NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        
        // [currentTarget setInputSize:pixelSize atIndex:textureIndexOfTarget];
        [currentTarget setInputTexture:outputTexture atIndex:textureIndexOfTarget];
        [currentTarget setInputCommandBuffer:sharedcommandBuffer atIndex:textureIndexOfTarget];//update every frame
        [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndexOfTarget withFrameData:nil];
    }
    
    
}

- (void)removeAllTargets;
{
    [super removeAllTargets];
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

@end
