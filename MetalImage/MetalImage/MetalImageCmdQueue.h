//
//  MetalImageCmdQueue.h
//  MetalImage
//
//  Created by xuqing on 11/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//
//Details refer to:https://developer.apple.com/library/prerelease/content/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Cmd-Submiss/Cmd-Submiss.html#//apple_ref/doc/uid/TP40014221-CH3-SW1


#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import "AssertLoader/MetalImageTexture.h"

typedef enum {
    kMetalImageNoRotation,
    kMetalImageRotateLeft,
    kMetalImageRotateRight,
    kMetalImageFlipVertical,
    kMetalImageFlipHorizonal,
    kMetalImageRotateRightFlipVertical,
    kMetalImageRotateRightFlipHorizontal,
    kMetalImageRotate180
} MetalImageRotationMode;


@interface MetalImageCmdQueue : NSObject

@property(nonatomic, readonly) id <MTLCommandQueue> sharedCommandQueue;
@property(nonatomic, readonly) dispatch_semaphore_t cmdBuffer_process_semaphore;

///////////////////////////////////////////////////////////
+(id <MTLDevice>)getGlobalDevice;
+ (MetalImageCmdQueue *)sharedImageProcessingCmdQueue;
+(dispatch_semaphore_t)getSemaphore;

+(id <MTLCommandQueue>) getGlobalCommandQueue;
+(id <MTLCommandBuffer>) getNewCommandBuffer;

-(void)loadCommandEncoder:(NSArray*)renderArr;//renderEncoder, renderEncoder2, computeEncoder, BlitEncoder

-(long)getCPUThreadsNum;
-(void)runCommandQueue;
@end


@protocol MetalImageInput <NSObject>

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
- (void)setInputTexture:(MetalImageTexture *)newInputTexture atIndex:(NSInteger)textureIndex;
- (NSInteger)nextAvailableTextureIndex;
- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
-(void)setInputCommandBuffer:(id <MTLCommandBuffer>)cmdBuffer atIndex:(NSInteger)index;
//- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
//- (CGSize)maximumOutputSize;
//- (void)endProcessing;
//- (BOOL)shouldIgnoreUpdatesToThisTarget;
//- (BOOL)enabled;
//- (BOOL)wantsMonochromeInput;
//- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
@end
