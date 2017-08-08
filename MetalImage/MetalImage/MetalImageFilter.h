//
//  MetalImageFilter.h
//  MetalImage
//
//  Created by erickingxu on 1/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MetalImageOutput.h"
#import <simd/simd.h>

typedef struct filterPipelineState
{
    
    MTLPixelFormat                      depthPixelFormat;
    MTLPixelFormat                      stencilPixelFormat;
    NSUInteger                          sampleCount;
    MetalImageRotationMode                   orient;
    __unsafe_unretained  NSString*      vertexFuncNameStr;
    __unsafe_unretained  NSString*      fragmentFuncNameStr;
    __unsafe_unretained  NSString*      computeFuncNameStr;
    __unsafe_unretained  NSString*      textureImagePath;
}
METAL_PIPELINE_STATE;

@interface MetalImageFilter : MetalImageOutput<MetalImageInput>
{
    MetalImageTexture*              firstInputTexture;
    MetalImageCmdQueue*             filterCommandQueue;
    id <MTLComputePipelineState>    _caclpipelineState;
    
    id <MTLRenderPipelineState>     _renderpipelineState;
    MTLRenderPipelineDescriptor*    renderplineStateDescriptor;
    MTLRenderPassDescriptor*        renderPassDescriptor;
    
    id <MTLDepthStencilState>       _depthStencilState;
    MTLDepthStencilDescriptor*      renderDepthStateDesc;
    //Compute kernel parameters
    MTLSize                         _threadGroupSize;
    MTLSize                         _threadGroupCount;
    
    BOOL                            isEndProcessing;
    CGSize                          currentFilterSize;
    MetalImageRotationMode          inputRotation;
}

@property(readonly,  nonatomic)id <MTLDevice>              filterDevice;
@property(readwrite, nonatomic)id <MTLBuffer>              verticsBuffer;
@property(readwrite, nonatomic)id <MTLBuffer>              coordBuffer;

@property(readwrite, nonatomic)id <MTLLibrary>             filterLibrary;
@property(nonatomic)  MTLPixelFormat depthPixelFormat;
@property(nonatomic)  MTLPixelFormat stencilPixelFormat;

-(id)initWithMetalPipeline:(METAL_PIPELINE_STATE*)pline;

-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer;

///attachment is real metal txture
-(void)setInputAttachment:(id<MTLTexture>)texture  withWidth: (int)w withHeight:(int)h;
-(id<MTLTexture>)outputAttachment;

////////////////////////Rendering//////////////////////////
- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
- (CGSize)outputFrameSize;
-(CGSize)inputFrameSize;
-(BOOL)initRenderPassDescriptorFromTexture:(id <MTLTexture>)textureForOutput;
@end
