//
//  MetalImageFaceShapenFilter.m
//  MetalImage
//
//  Created by ericking on 7/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//  Paper refer to :http://www.gson.org/thesis/warping-thesis.pdf

#import "MetalImageFaceShapenFilter.h"

static const unsigned length = 6;//
static const unsigned length_pagealigned = (length/4096 +1)*4096;
#define GETLENTH(x) sqrt(pow(x[0], 2.0) + pow(x[1], 2.0))

#define GETPOINT_X(x) facePts[x * 2]

#define GETPOINT_Y(y) facePts[y * 2 + 1]

@implementation MetalImageFaceShapenFilter
{
   //float                       faceArray[length_pagealigned]  __attribute__((aligned(4096)));
    float                       faceArray[6];
    id <MTLBuffer>              _fBuffer;
    simd::float4                pointSprits[10];
    id <MTLBuffer>              _pointSpiritBuffer;
    
}

-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"eyefSharpen";
    peline.vertexFuncNameStr  =  @"pointSpiritVertex";
    peline.fragmentFuncNameStr=  @"roundSpiritFragment";
    
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    

    if (!self.filterDevice )
    {
        return nil;
    }
    _fBuffer =  [self.filterDevice newBufferWithBytes:&faceArray[0] length:6*sizeof(float) options:MTLResourceStorageModeShared];
    return self;
}

-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    [filterCommandQueue.sharedCommandQueue insertDebugCaptureBoundary];
    if (commandBuffer )
    {
        ///render pass joint
        if (_renderpipelineState)
        {
            if(renderplineStateDescriptor)
            {
                id <MTLRenderCommandEncoder>  renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];//should keep renderPassDescp is ture...
                
                [renderEncoder pushDebugGroup:@"pointSpirit_encoder"];
                
                [renderEncoder setVertexBuffer:_pointSpiritBuffer offset:0 atIndex:0];
                
                [renderEncoder setRenderPipelineState:_renderpipelineState];
                
                // tell the render context we want to draw our primitives
                [renderEncoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:0 vertexCount:10 instanceCount:1];
                
                [renderEncoder endEncoding];
                [renderEncoder popDebugGroup];
            }
        
        }
        if(_caclpipelineState)
        {
            id <MTLComputeCommandEncoder>  cmputEncoder = [commandBuffer computeCommandEncoder];
            if (cmputEncoder)
            {
                [cmputEncoder  setComputePipelineState:_caclpipelineState];
                [cmputEncoder  setTexture: firstInputTexture.texture atIndex:0];
                [cmputEncoder  setTexture: outputTexture.texture atIndex:1];
                [cmputEncoder  setBuffer:  _fBuffer offset:0 atIndex:0];
                [cmputEncoder  dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
                [cmputEncoder  endEncoding];
            }
        }
        else
        {
            outputTexture = firstInputTexture;
        }
    }
    //end compute encoder
    
}

- (void)renderToTextureWithVertices:(const simd::float4 *)vertices textureCoordinates:(const simd::float2 *)textureCoordinates withAttachmentData:(Texture_FrameData*)pFrameData
{
    if (!firstInputTexture)
    {
        return;
    }
    //new output texture for next filter
    if (_threadGroupSize.width == 0 || _threadGroupSize.height == 0 || _threadGroupSize.depth == 0 )
    {
        _threadGroupSize = MTLSizeMake(16, 16, 1);
    }
    //calculate compute kenel's width and height
    
    NSUInteger nthreadWidthSteps  = (firstInputTexture.width + _threadGroupSize.width - 1) / _threadGroupSize.width;
    NSUInteger nthreadHeightSteps = (firstInputTexture.height+ _threadGroupSize.height - 1)/ _threadGroupSize.height;
    _threadGroupCount             = MTLSizeMake(nthreadWidthSteps, nthreadHeightSteps, 1);
    
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        
        if (outputTexture ==  nil)
        {
            outputTexture  = [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight: firstInputTexture.height];
            [outputTexture loadTextureIntoDevice: self.filterDevice];
           
        }
        
    });
    
    if (outputTexture && ![self initRenderPassDescriptorFromTexture:firstInputTexture.texture])
    {
        _renderpipelineState = nil;//cant render sth on ouputTexture...
    }
    //load encoder for compute input texture
    
    AttachmentDataArr* faceFrameDataArr = &(pFrameData->attachFrameDataArr);
    
    FaceFrameData* facePts = &(faceFrameDataArr->faceItemArr[0]);
    int cnt = faceFrameDataArr->faceCount;
    [self facePointsTransform:facePts->facePoints withWidth:firstInputTexture.width withHeight:firstInputTexture.height inCount: cnt withLevel:0.95];
    
    if (sharedcommandBuffer)
    {
        [self caculateWithCommandBuffer:sharedcommandBuffer];
    }
    
}

//////draw filter pass to view for assigned texture
-(BOOL)initRenderPassDescriptorFromTexture:(id <MTLTexture>)textureForOutput
{
    if (nil == renderPassDescriptor)//could be resue....
    {
        renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
    }
    MTLRenderPassColorAttachmentDescriptor* colorAttachment  = renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture         = textureForOutput;//target for draw
    colorAttachment.loadAction      = MTLLoadActionLoad;
    colorAttachment.clearColor      = MTLClearColorMake(0.0, 0.0, 0.0, 0.5);//black
    colorAttachment.storeAction     = MTLStoreActionStore;
    //using default depth and stencil dscrptor...
    
    return YES;
}
-(void)facePointsTransform:(float*)facePts withWidth:(int)width withHeight:(int)height inCount:(int)pointsCount withLevel:(float)thinlevel
{

    float whRatio = ((float)width) / height;
    simd::float2 leftEye = {0,0};
    simd::float2 rightEye ={0,0};
    simd::float2 nosePoint = {0,0} ;
    
    if (48 == pointsCount)
    {
        leftEye = {GETPOINT_X(74)*whRatio, GETPOINT_Y(74)};
        rightEye = {GETPOINT_X(77)*whRatio, GETPOINT_Y(77)};
        nosePoint = {GETPOINT_X(46)*whRatio, GETPOINT_Y(46)};
        ////point need to be fliped by texture rotation
        pointSprits[0]  = {static_cast<float>(2.0 * GETPOINT_X(4) - 1.0), static_cast<float>((-1.0 * (2.0 * GETPOINT_Y(4) - 1.0))), 0.0, 1.0};
        pointSprits[1]  = {static_cast<float>(2.0 * GETPOINT_X(16) - 1.0),static_cast<float>(-1.0 * (2.0 * GETPOINT_Y(16) - 1.0)), 0.0, 1.0};
        
        pointSprits[2]  = {static_cast<float>(2.0 * GETPOINT_X(28) - 1.0),static_cast<float>(-1.0 * (2.0 * GETPOINT_Y(28) - 1.0)), 0.0, 1.0};
        pointSprits[3]  = {static_cast<float>(2.0 * GETPOINT_X(46) - 1.0),static_cast<float>(-1.0 * (2.0 * GETPOINT_Y(46) - 1.0)), 0.0, 1.0};
        
        pointSprits[4]  = {static_cast<float>(2.0 * GETPOINT_X(74) - 1.0),static_cast<float>(-1.0 * (2.0 * GETPOINT_Y(74) - 1.0)), 0.0, 1.0};
        pointSprits[5]  = {static_cast<float>(2.0 * GETPOINT_X(77) - 1.0),static_cast<float>(-1.0 * (2.0 * GETPOINT_Y(77) - 1.0)),0.0, 1.0};
        
        pointSprits[6]  = {static_cast<float>(2.0 * GETPOINT_X(13) - 1.0),static_cast<float>(-1.0 * (2.0 * GETPOINT_Y(13) - 1.0)), 0.0, 1.0};
        pointSprits[7]  = {static_cast<float>(2.0 * GETPOINT_X(19) - 1.0),static_cast<float>(-1.0 * (2.0 * GETPOINT_Y(19) - 1.0)),0.0, 1.0};
        
        pointSprits[8]  = {static_cast<float>(2.0 * GETPOINT_X(10) - 1.0), static_cast<float>(-1.0 * (2.0 * GETPOINT_Y(10) - 1.0)), 0.0,1.0};
        pointSprits[9]  = {static_cast<float>(2.0 * GETPOINT_X(22) - 1.0), static_cast<float>(-1.0 * (2.0 * GETPOINT_Y(22) - 1.0)), 0.0,1.0};
        
        
        _pointSpiritBuffer = [self.filterDevice newBufferWithBytes:&pointSprits[0] length:40*sizeof(float) options:MTLResourceStorageModeShared];
    }
    faceArray[0] = leftEye.x;
    faceArray[1] = leftEye.y;
    faceArray[2] = rightEye.x;
    faceArray[3] = rightEye.y;
    faceArray[4] = nosePoint.x;
    faceArray[5] = nosePoint.y;
    
    //_fBuffer =  [self.filterDevice newBufferWithBytesNoCopy:&faceArray[0] length: 15*sizeof(float) options:MTLResourceStorageModeShared deallocator:nil];///for large face array data
    _fBuffer =  [self.filterDevice newBufferWithBytes:&faceArray[0] length:6*sizeof(float) options:MTLResourceStorageModeShared];
}
@end
