//
//  MetalImagePicture.m
//  MetalImage
//
//  Created by xuqing on 3/8/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImagePicture.h"
#import "MetalImageCmdQueue.h"

@implementation MetalImagePicture

-(id)initWithImage:(UIImage*)img
{
    if (!(self = [self initWithCGImage:img.CGImage smoothlyScaleOutput:NO]))
    {
        return nil;
    }
    
    return self;
}

-(id)initWithCGImage:(CGImageRef)image  smoothlyScaleOutput: (BOOL)bSmoothly;
{
    if (!(self = [super init]) || !image)
    {
        return nil;
    }
    
    hasdProcessed = NO;
    imgDevice  = [MetalImageCmdQueue getGlobalDevice];
    
    imageUpdateSemaphore = dispatch_semaphore_create(0);
    dispatch_semaphore_signal(imageUpdateSemaphore);
    
    
    // TODO: Dispatch this whole thing asynchronously to move image loading off main thread
    CGFloat widthOfImage = CGImageGetWidth(image);
    CGFloat heightOfImage = CGImageGetHeight(image);
    
    // If passed an empty image reference, CGContextDrawImage will fail in future versions of the SDK.
    NSAssert( widthOfImage > 0 && heightOfImage > 0, @"Passed image must not be empty - it should be at least 1px tall and wide");
    
    pixelSize = CGSizeMake(widthOfImage, heightOfImage);
    //load it into texture and build a output texture for reslut
    outputTexture =  [[MetalImageTexture alloc] initWithImage:image andWithMetalDevice:imgDevice];
    return self;
}


- (void)dealloc;
{
    outputTexture = nil;
#if !OS_OBJECT_USE_OBJC
    if (imageUpdateSemaphore != NULL)
    {
        dispatch_release(imageUpdateSemaphore);
    }
#endif
}

#pragma mark -
#pragma mark Image rendering

- (void)removeAllTargets;
{
    [super removeAllTargets];
    hasdProcessed = NO;
}

- (void)processImage;
{
    [self processImageWithCompletionHandler:nil];
}

- (BOOL)processImageWithCompletionHandler:(void (^)(void))completionFunc;
{
    hasdProcessed = YES;
    
    
    if (dispatch_semaphore_wait(imageUpdateSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return NO;
    }
    
        for (id<MetalImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
           // [currentTarget setInputSize:pixelSize atIndex:textureIndexOfTarget];
            [currentTarget setInputTexture:outputTexture atIndex:textureIndexOfTarget];
            [currentTarget setInputCommandBuffer:sharedcommandBuffer atIndex:textureIndexOfTarget];
            [currentTarget newFrameReadyAtTime:kCMTimeIndefinite atIndex:textureIndexOfTarget];
        }
        
        dispatch_semaphore_signal(imageUpdateSemaphore);
        
        if (completionFunc != nil)
        {
            completionFunc();
        }
    
    return YES;
}

@end
