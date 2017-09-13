//
//  MetalImageView.h
//  MetalImage
//
//  Created by erickingxu on 2/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//
//  CAMetalLayer must be used by A7 Chip ,not support simulator
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>
#import "MetalImageCmdQueue.h"


@class MetalImageTexture;

@interface MetalImageView : UIView<MetalImageInput>
{
    MetalImageRotationMode inputRotation;
}
@property(nonatomic, readonly) id<MTLDevice>                device;
//created by CAMetalLayer for current drawing...
@property(nonatomic, readonly) id<CAMetalDrawable>          currentDrawable;

@property(nonatomic) MTLPixelFormat                         depthPixelFormat;
@property(nonatomic) MTLPixelFormat                         stencilPixelFormat;
@property(nonatomic) NSUInteger                             sampleCount;
@property(readwrite, nonatomic)id <MTLBuffer>               verticsBuffer;
@property(readwrite, nonatomic)id <MTLBuffer>               coordBuffer;
@property(readwrite, nonatomic)id <MTLRenderPipelineState>  pipelineState;
@property(readwrite, nonatomic)id <MTLDepthStencilState>    depthStencilState;

@property(readwrite, nonatomic)MetalImageRotationMode       inputRotation;
// view controller will be call off the main thread

// release any color/depth/stencil resources. view controller will call when paused.
- (void)releaseTextures;
////////////////////////////////////////////////////////////////////////////////////
@end
