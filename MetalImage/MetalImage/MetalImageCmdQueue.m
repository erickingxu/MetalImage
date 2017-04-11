//
//  MetalImageCmdQueue.m
//  MetalImage
//
//  Created by erickingxu on 11/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageCmdQueue.h"


@interface MetalImageCmdQueue()
{
    long                    kCmdBuffersforProcessing;  //handle by different cpu threads
   
    NSMutableDictionary     *shareCommandBufferDict;//restore differ functional encoder
    

    
}

//@property(readonly, nonatomic)  id <MTLDevice>  metalImageDevice;
@end

@implementation MetalImageCmdQueue
@synthesize  sharedCommandQueue             = _sharedCommandQueue;
@synthesize  cmdBuffer_process_semaphore    = _cmdBuffer_process_semaphore;
/////////////////////////////////////////////////////////////////////////////////////////

 static      id <MTLDevice>          _metalImageDevice = nil;

//+(id <MTLDevice>)getDeviceInstance;
//{
//    if (!_metalImageDevice)
//    {
//        assert(0);
//        NSLog(@"device should be created only once!!!");
//        if ( !(_metalImageDevice = MTLCreateSystemDefaultDevice()) )
//        {
//            return nil;
//        }
//    }
//    return _metalImageDevice;
//}

// Based on Colin Wheeler's example here: http://cocoasamurai.blogspot.com/2011/04/singletons-your-doing-them-wrong.html
+ (MetalImageCmdQueue *)sharedImageProcessingCmdQueue;
{
    static dispatch_once_t pred;
    static MetalImageCmdQueue *sharedImageProcessingCmdQueue = nil;
   
    dispatch_once(&pred, ^{

        _metalImageDevice = MTLCreateSystemDefaultDevice();
        sharedImageProcessingCmdQueue = [[[self class] alloc] init];
    });
    return sharedImageProcessingCmdQueue;
}

-(id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    kCmdBuffersforProcessing = 3;
    _cmdBuffer_process_semaphore = dispatch_semaphore_create(kCmdBuffersforProcessing);
    
    _sharedCommandQueue          = [_metalImageDevice newCommandQueue];
    _sharedCommandQueue.label    = @"Metal Command Queue";
    return self;
}

+(id <MTLCommandQueue>) getGlobalCommandQueue
{
    return [self sharedImageProcessingCmdQueue].sharedCommandQueue ;
}

+(id <MTLDevice>) getGlobalDevice
{
    if (![self sharedImageProcessingCmdQueue] || !_metalImageDevice)
    {
        assert(0);
        NSLog(@"Create Device is failed!");
    }
    return _metalImageDevice;
}

+(id <MTLCommandBuffer>) getNewCommandBuffer
{
    return [[self sharedImageProcessingCmdQueue].sharedCommandQueue commandBuffer];//new a cmd buffer for new encoders...
}

+(dispatch_semaphore_t)getSemaphore
{
    return [self sharedImageProcessingCmdQueue].cmdBuffer_process_semaphore;
}

-(void)loadCommandEncoder:(NSArray*)renderArr     //renderEncoder, renderEncoder2, computeEncoder, BlitEncoder
{
    
}
-(long)getCPUThreadsNum
{
    return kCmdBuffersforProcessing;
}

-(void)runCommandQueue
{
    
}

@end
