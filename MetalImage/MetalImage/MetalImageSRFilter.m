//
//  MetalImageSRFilter.m
//  MetalImage
//
//  Created by xuqing on 2022/1/26.
//  Copyright © 2022 erickingxu. All rights reserved.
//

#import "MetalImageSRFilter.h"
#import "simd/simd.h"
#import "MetalImageDeCNN.h"
#import "MetalImageBaseCNN.h"

@implementation MetalImageSRFilter
{
    id<MTLCommandQueue>             _srQueue;
    id<MTLDevice>                   _srDevice;
    Conv2dWrapper*                  _down_conv;
    DeConv2dWrapper*                _up_deconv;
    MPSImage*                       _inMPSImage;
    MPSImageDescriptor*             _upconv_descr;
    MPSImageDescriptor*             _downconv_descr;

    id<MTLComputePipelineState>     rgba_16f2u8_pipelinestate;
}


-(id)init
{
    MetalImageCmdQueue* mque = [MetalImageCmdQueue  sharedImageProcessingCmdQueue];
    if (self = [super init]) {
        if (!mque) {
            return Nil;
        }
        _srQueue = mque.sharedCommandQueue ;
        if (_srQueue) {
            _srDevice = _srQueue.device;
        }
        MPSCNNNeuron* relu = [[MPSCNNNeuron alloc] initWithDevice:_srDevice neuronDescriptor:[MPSNNNeuronDescriptor cnnNeuronDescriptorWithType:MPSCNNNeuronTypeReLU a:0.0] ];
        MPSImageFeatureChannelFormat fmt = MPSImageFeatureChannelFormatFloat16;
        int width = 1280, height = 720;
        MPSImageDescriptor* input_descr = [MPSImageDescriptor imageDescriptorWithChannelFormat:fmt width:width height:height featureChannels:1];
        input_descr.storageMode = MTLStorageModePrivate;
        
        _inMPSImage = [[MPSImage alloc] initWithDevice:_srDevice imageDescriptor:input_descr];
        
       
        _downconv_descr = [MPSImageDescriptor imageDescriptorWithChannelFormat:fmt width:width/2 height:height/2 featureChannels:8];
        _downconv_descr.storageMode = MTLStorageModePrivate;
        
        _upconv_descr = [MPSImageDescriptor imageDescriptorWithChannelFormat:fmt width:width height:height featureChannels:1];
        _upconv_descr.storageMode = MTLStorageModePrivate;
  
        //init conv and pooling
        CGSize down_ks = CGSizeMake(3, 3);
        CGSize down_ss = CGSizeMake(2, 2);
        _down_conv = [[Conv2dWrapper alloc] initWithDevice:_srDevice kernelParamName:@"down0_conv" kernelSize:down_ks inputFeatureChannels:1 neuroActivator:relu padding:YES strideSize:down_ss outputFeatureChannels:8 outputFeatureChannelOffset:0 byGroupNum:1];
        
        down_ks.width = 4, down_ks.height = 4;
        down_ss.width = 2, down_ss.height = 2;
        _up_deconv = [[DeConv2dWrapper alloc] initWithDevice:_srDevice kernelParamName:@"up0_deconv" kernelSize:down_ks inputFeatureChannels:8 neuroActivator:Nil padding:CGSizeMake(1, 1) strideSize:down_ss outputFeatureChannels:1 outputFeatureChannelOffset:0 byGroupNum:1];
        
        //
        METAL_PIPELINE_STATE peline ;
        //peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
        peline.stencilPixelFormat =  MTLPixelFormatInvalid;
        peline.orient             =  kMetalImageNoRotation;
        peline.sampleCount        =  1;
        peline.computeFuncNameStr =  @"rgb2bgr_float";
        peline.vertexFuncNameStr  = @"";
        peline.fragmentFuncNameStr= @"";
        if (!(self = [super initWithMetalPipeline:&peline]))
        {
            return nil;
        }
        //bgr2rgb_16fto8u
        METAL_PIPELINE_STATE bgru8_pipeline ;
        bgru8_pipeline.computeFuncNameStr =  @"convertYCbCr2RGBA";
        bgru8_pipeline.vertexFuncNameStr  = @"";
        bgru8_pipeline.fragmentFuncNameStr= @"";
        rgba_16f2u8_pipelinestate = [self getComputePipeLineFrom:&bgru8_pipeline];
        if (!rgba_16f2u8_pipelinestate) {
            NSLog(@"some compute pipeline is Nil...");
            return  Nil;
        }
    }
    
    return self;
}


-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    [filterCommandQueue.sharedCommandQueue insertDebugCaptureBoundary];
    if (commandBuffer && _caclpipelineState)
    {
        id <MTLComputeCommandEncoder>  enc0 = [commandBuffer computeCommandEncoder];
        if (enc0)
        {
            
            int ww= (int)_inMPSImage.width;
            int hh= (int)_inMPSImage.height;
            MTLSize num_threadspergroup = MTLSizeMake(16, 16, 1);
            MTLSize num_groups = MTLSizeMake(( ww + num_threadspergroup.width -  1) / num_threadspergroup.width, ( hh + num_threadspergroup.height -  1) / num_threadspergroup.height, 1);
           
            // Set the pipeline state.
            [enc0 setComputePipelineState:_caclpipelineState];
            [enc0 setTexture:firstInputTexture.texture atIndex:0];
            [enc0 setTexture:_inMPSImage.texture atIndex:1];

            [enc0 dispatchThreadgroups:num_groups threadsPerThreadgroup:num_threadspergroup];
            [enc0 endEncoding];

            MPSTemporaryImage* up_image = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:_upconv_descr];
            MPSTemporaryImage* down_image = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:_downconv_descr];
            [_down_conv encodeFrom:_inMPSImage toDestination:down_image withCommandBuffer:commandBuffer];
            [_up_deconv encodeFrom:down_image toDestination:up_image withCommandBuffer:commandBuffer];
         
            // Create compute encoder.
            id<MTLComputeCommandEncoder> enc = [commandBuffer computeCommandEncoder];
            // Set the pipeline state.
            [enc setComputePipelineState:rgba_16f2u8_pipelinestate];
            [enc setTexture:up_image.texture atIndex:0];
            [enc setTexture:secondInputTexture.texture atIndex:1];
            [enc setTexture:outputTexture.texture atIndex:2];

            ww= outputTexture.width;
            hh= outputTexture.height;
            num_groups = MTLSizeMake(( ww + num_threadspergroup.width -  1) / num_threadspergroup.width, ( hh + num_threadspergroup.height -  1) / num_threadspergroup.height, 1);

            [enc dispatchThreadgroups:num_groups threadsPerThreadgroup:num_threadspergroup];
            [enc endEncoding];
            //push to gpu
            up_image.readCount = 0;
            down_image.readCount = 0;
            //[commandBuffer commit];
        }
    }
    //end if
}



@end
