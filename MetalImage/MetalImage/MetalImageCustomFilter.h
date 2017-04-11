//
//  MetalImageCustomFilter.h
//  MetalImage
//
//  Created by erickingxu on 8/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//
///////////////////You can rewrite it by yourself with all several pass or compute kernel here //////////////
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalImageCustomView.h"
#import "MetalImageTexture.h"

typedef enum MetalOrientation
{
    MetalOrientationUnknown,
    MetalOrientationPortrait,            // Device oriented vertically, home button on the bottom
    MetalOrientationPortraitUpsideDown,  // Device oriented vertically, home button on the top
    MetalOrientationLandscapeLeft,       // Device oriented horizontally, home button on the right
    MetalOrientationLandscapeRight,      // Device oriented horizontally, home button on the left
    MetalOrientationFaceUp,              // Device oriented flat, face up
    MetalOrientationFaceDown,             // Device oriented flat, face down
}
METAL_ORIENTATION;


typedef struct ImagePipelineState
{
    
    MTLPixelFormat                      depthPixelFormat;
    MTLPixelFormat                      stencilPixelFormat;
    NSUInteger                          sampleCount;
    METAL_ORIENTATION                   orient;
    __unsafe_unretained  NSString*      vertexFuncNameStr;
    __unsafe_unretained  NSString*      fragmentFuncNameStr;
    __unsafe_unretained  NSString*      computeFuncNameStr;
    __unsafe_unretained  NSString*      textureImagePath;
}
METAL_FILTER_PIPELINE_STATE;


@interface MetalImageCustomFilter : NSObject<MetalImageRenderDelegate>
@property(nonatomic)  MTLPixelFormat depthPixelFormat;
@property(nonatomic)  MTLPixelFormat stencilPixelFormat;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//functions
-(id <MTLDevice> ) getFilterDevice;
-(id <MTLLibrary> ) getShaderLibrary;
-(id <MTLCommandBuffer>) getNewCommandBuffer;
-(dispatch_semaphore_t)getAvialiableDrawableSem;
// load all assets before triggering rendering
- (BOOL)configure:(METAL_FILTER_PIPELINE_STATE*)plinestate ;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
@end
