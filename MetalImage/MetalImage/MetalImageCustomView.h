//
//  MetalImageCustomView.h
//  MetalImage
//
//  Created by erickingxu on 12/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>

@class MetalImageCustomView;
@class MetalImageTexture;

@protocol MetalImageRenderDelegate <NSObject>
@required
-(void)filterRender:(MetalImageCustomView*)metalView withDrawableTexture:(MetalImageTexture*)drawableTexture inCommandBuffer:(id <MTLCommandBuffer>)cmdBuffer;

@end


@interface MetalImageCustomView : UIView

@property(nonatomic, readonly) id<MTLDevice>            device;
@property(nonatomic, readonly) id<CAMetalDrawable>      currentDrawable;//created by CAMetalLayer for current drawing...
@property(nonatomic, readonly) MTLRenderPassDescriptor *renderPassDescriptor;
@property(nonatomic) MTLPixelFormat                     depthPixelFormat;
@property(nonatomic) MTLPixelFormat                     stencilPixelFormat;
@property(nonatomic) NSUInteger                         sampleCount;

@property (nonatomic, weak) IBOutlet id <MetalImageRenderDelegate> filterDelegate;
// view controller will be call off the main thread
- (void)display;
// release any color/depth/stencil resources. view controller will call when paused.
- (void)releaseTextures;
////////////////////////////////////////////////////////////////////////////////////
@end


