//
//  ViewController.m
//  MetalVideoFilter
//
//  Created by erickingxu on 10/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "ViewController.h"
#import "MetalImage.h"
#import <AVFoundation/AVFoundation.h>
//////////////////////////////////////////////////////////////////////////
#define OF_USE_FACE

#ifdef OF_USE_FACE
///should be add face tracking header file for some API interface
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

#endif



//////////////////////////////////////////////////////////////////////////
@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession* _session;
    AVCaptureDeviceInput *_input;
    AVCaptureDevice *_videoDevice;

    AVCaptureVideoDataOutput *_dataOutput;
    AVCaptureDeviceDiscoverySession *_deviceDiscoverySession;
    
    
    id <MTLDevice>                  _metalDevice;
    CVMetalTextureCacheRef          videoTextureCache;
    
    int                             videoWidth;
    int                             videoHeight;
    MetalImageCmdQueue*             videoCommandQueue;
    MetalImageRotationMode          inputRotation;
    MetalImageFaceShapenFilter*     _fsharpenFilter;
    MetalImageView*                 imageView ;
    Texture_FrameData               _frameData;

}
@end

@implementation ViewController
////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    videoWidth =  videoHeight = 0;
    [self metalFilterInit];
    
    [self setupFaceTracking];
    [self setupVideoCamera];
}

-(void)metalFilterInit
{
    _metalDevice = [MetalImageCmdQueue getGlobalDevice];
    _fsharpenFilter = [[MetalImageFaceShapenFilter alloc] init];
    imageView = (MetalImageView*)self.view;
    imageView.inputRotation  = kMetalImageRotate180;
    [_fsharpenFilter addTarget:imageView];
    
    videoTextureCache = nil;
}
-(BOOL)setupFaceTracking
{
#ifdef OF_USE_FACE
    //
    // Init face landmark library.
    //
    
    #endif
    return YES;
}

- (void)setupVideoCamera
{
    CVMetalTextureCacheFlush(videoTextureCache, 0);
    CVReturn textCachRes = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, _metalDevice, NULL, &videoTextureCache);
    if(textCachRes)
    {
        NSLog(@"ERROR: Can not create a video texture cache!!! ");
        assert(0);
    }

    _session = [[AVCaptureSession alloc] init];
    _deviceDiscoverySession = [AVCaptureDeviceDiscoverySession
                               discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                               mediaType:AVMediaTypeVideo
                               position:AVCaptureDevicePositionFront];
    [_session setSessionPreset:AVCaptureSessionPreset1280x720];
    
    [self rotateCamera:YES];//default front camera

    [_session startRunning];
    
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
            return device;
    }
    return nil;
}

- (void)rotateCamera:(BOOL)switchCamrea
{
    [_session beginConfiguration];
    NSArray *devices  = _deviceDiscoverySession.devices;
    if (switchCamrea)
    {
        for (AVCaptureDevice* device in devices)
        {
            if ([device hasMediaType:AVMediaTypeVideo])
            {
                if (((AVCaptureDeviceInput*)_input).device.position == AVCaptureDevicePositionBack)
                {
                    _videoDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
                    break;
                }
                else
                {
                    _videoDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
                    break;
                }
            }
        }
    }
    else{
        for (AVCaptureDevice* device in devices)
        {
            if ([device hasMediaType:AVMediaTypeVideo])
            {
                if ([device position] == AVCaptureDevicePositionFront)
                {
                    _videoDevice = device;
                    break;
                }
            }
        }
    }
    NSError *error;
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice error:&error];
    [_session addInput:_input];
    [self cameraOutConfigure];
    [_session commitConfiguration];
}


- (void)cameraOutConfigure
{
    _dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_session addOutput:_dataOutput];
    AVCaptureConnection* videoConnection = [_dataOutput connectionWithMediaType:AVMediaTypeVideo];
    [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [_dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    //
    // Set to RGBA.
    //
    [_dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                              forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    //
    // Set dispatch to be on the main thread so OpenGL can do things with the data.
    //
    [_dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

///////////////////////////////////////////////////////////////////////////////////
///samplebuffer delegate func
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVReturn error;
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t *baseAddress = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    int bytesPerRow =(int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int height = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    int width = (int)CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    
    CVImageBufferRef sourceImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVMetalTextureRef textureRef;
    error = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, sourceImageBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &textureRef);
    
    if (error)
    {
        NSLog(@">> ERROR: Couldnt create texture from image");
        assert(0);
    }
    id<MTLTexture> txt = CVMetalTextureGetTexture(textureRef);
    if (width != [_fsharpenFilter inputFrameSize].width || height != [_fsharpenFilter inputFrameSize].height)
    {
        [_fsharpenFilter setInputAttachment: txt withWidth:width withHeight:height];
    }
    
    if (!txt)
    {
        NSLog(@">> ERROR: Couldn't get texture from texture ref");
        assert(0);
    }

    
    [_fsharpenFilter fireOn];
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [self videoSampleBufferProcessing:currentTime withFramedata: baseAddress  withFormat:3 withWidth: width withHeight: height inBytesPerRow: bytesPerRow];
    
    
    CVBufferRelease(textureRef);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
}

////filter driver for animate the filter chain working one by one
-(void)videoSampleBufferProcessing:(CMTime)frameTime withFramedata:(unsigned char*)baseAddress  withFormat:(int)format withWidth: (int)width withHeight: (int)height inBytesPerRow: (int)bytesPerRow
{
    _frameData.imageData = baseAddress;
    _frameData.width = width;
    _frameData.height = height;
    _frameData.widthStep = bytesPerRow;
    _frameData.format = format;
    _frameData.attachFrameDataArr.faceCount = 0;
    AttachmentDataArr *pfdata = &(_frameData.attachFrameDataArr);
    if(!faceCatch(baseAddress, width, height, bytesPerRow,format, &pfdata))
    {
        _frameData.attachFrameDataArr.faceCount = 0;
    }
    else
    {
        _frameData.attachFrameDataArr.faceCount = 106;
    }
    [_fsharpenFilter newFrameReadyAtTime:frameTime atIndex:0 withFrameData: &_frameData];
}

////$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$////

float Distance(float* p1, float* p2)
{
    float a = p1[0] - p2[0];
    float b = p1[1] - p2[1];
    return sqrtf(a * a + b * b);
}


static bool faceCatch(unsigned char* data, int width, int height, int bytesPerRow, int format, AttachmentDataArr** faceFrameDataArr)
{
    int iResult = -1, iFaceCount = 0;
    //start face detection and tracking....
    
    if (0 == iResult && iFaceCount > 0)
    {
        (*faceFrameDataArr)->faceCount = iFaceCount;
        for (int i = 0; i < iFaceCount ; i ++)
        {
            (*faceFrameDataArr)->faceItemArr[i].facePointsCount = 48;
            void* megFace = NULL;
            void* facialPoints = NULL;//Face.points_array;
            for (int j = 0; j < 48; ++j)
            {
                (*faceFrameDataArr)->faceItemArr[i].facePoints[j * 2] = 0;//(facialPoints[j].x / (float)width);
                (*faceFrameDataArr)->faceItemArr[i].facePoints[j * 2 + 1] = 0;//( facialPoints[j].y / (float)height);
            }
            
            //should update num and keep same together
            (*faceFrameDataArr)->faceItemArr[i].facePointsCount = 48;
        }
        
        return true;
    }
    
    return false;
}
@end
