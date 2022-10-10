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
    BOOL                             _isYUVVideo;
    int                             videoWidth;
    int                             videoHeight;
    MetalImageCmdQueue*             videoCommandQueue;
    MetalImageRotationMode          inputRotation;
    id<MTLTexture>                  _videoTexture[2];
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
    _isYUVVideo = NO;
    [self setupVideo];
    
    return self;
}

-(id)initWithVideoType:(int)video_type
{
    if (!(self = [super init]))
    {
        return nil;
    }
    videoWidth =  videoHeight = 0;
    videoDevice = [MetalImageCmdQueue getGlobalDevice];
    videoTextureCache = nil;
    _isYUVVideo = (video_type==2)? YES:NO;
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
    [_captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    AVCaptureDevice *videoCaptureDevice  = nil;
    NSArray* deviceArr = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice* device  in deviceArr)
    {
        if ([device position] == AVCaptureDevicePositionBack)
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
    [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:(_isYUVVideo ? kCVPixelFormatType_420YpCbCr8BiPlanarFullRange : kCVPixelFormatType_32BGRA)]
                                                             forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    // Set dispatch to be on the main thread to create the texture in memory and allow Metal to use it for rendering
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [_captureSession addOutput:dataOutput];
    [_captureSession commitConfiguration];
    
    // this will trigger capture on its own queue
    [_captureSession startRunning];
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVReturn err;
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    float y_width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    float y_height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    
    CVMetalTextureRef y_texture , uv_texture;
    if (_isYUVVideo) {
        err = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, pixelBuffer, nil, MTLPixelFormatR8Unorm, y_width, y_height, 0, &y_texture);
        
        float uv_width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
        float uv_height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
        err = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, pixelBuffer, nil, MTLPixelFormatRG8Unorm, uv_width, uv_height, 1, &uv_texture);
     
    }else{
        err = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, y_width, y_height, 0, &y_texture);
    }

    if (err)
    {
        NSLog(@">> ERROR: Couldnt create texture from image");
        assert(0);
    }
    if (outputTexture.width != y_width || outputTexture.height!= y_height) {
        if (_isYUVVideo) {
            outputTexture = [[MetalImageTexture alloc] initWithWidth:(uint32_t)y_width withHeight:(uint32_t)y_height withFormat:MTLPixelFormatR8Unorm];
        }else{
            outputTexture = [[MetalImageTexture alloc] initWithWidth:(uint32_t)y_width withHeight:(uint32_t)y_height withFormat:MTLPixelFormatBGRA8Unorm];
        }
    }
    if (outputTexture_attched.width != y_width || outputTexture_attched.height!= y_height) {
        if (_isYUVVideo) {
            outputTexture_attched = [[MetalImageTexture alloc] initWithWidth:(uint32_t)y_width/2 withHeight:(uint32_t)y_height/2 withFormat:MTLPixelFormatRG8Unorm];
            [targetTextureIndices addObject:[NSNumber numberWithInteger:1] ];
            outputTexture_attched.texture = CVMetalTextureGetTexture(uv_texture);
            CVBufferRelease(uv_texture);
        }
    }
    outputTexture.texture = CVMetalTextureGetTexture(y_texture);
    
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [self fireOn];
    [self videoSampleBufferProcessing:currentTime];
    CVBufferRelease(y_texture);
}


-(void)videoSampleBufferProcessing:(CMTime)frameTime
{
    for (id<MetalImageInput> currentTarget in targets)
    {
        NSInteger indexOfObject = [targets indexOfObject:currentTarget];
        NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        
        [currentTarget setInputTexture:outputTexture atIndex:textureIndexOfTarget];
        if ([targetTextureIndices containsObject:[NSNumber numberWithInteger:1]]) {
            [currentTarget setInputTexture:outputTexture_attched atIndex:1];
        }
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
