//
//  MetalImageMpsCnn.h
//  MetalImage
//
//  Created by erickingxu on 22/3/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//


#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface MetalImageMpsCnn : MPSCNNConvolution
{
//    BOOL      padding;
//    uint      inWidth;
//    uint      inHeight;
    
}

/**
 Initializes a fully connected kernel.
 
 - Parameters:
 - kernelWidth: Kernel Width
 - kernelHeight: Kernel Height
 - inputFeatureChannels: Number feature channels in input of this layer
 - outputFeatureChannels: Number feature channels from output of this layer
 - neuronFilter: A neuronFilter to add at the end as activation, default is nil
 - device: The MTLDevice on which this SlimMPSCNNConvolution filter will be used
 - kernelParamsBinaryName: name of the layer to fetch kernelParameters by adding a prefix "weights_" or "bias_"
 - padding: Bool value whether to use padding or not
 - strideXY: Stride of the filter
 - destinationFeatureChannelOffset: FeatureChannel no. in the destination MPSImage to start writing from, helps with concat operations
 - groupNum: if grouping is used, default value is 1 meaning no groups
 
 - Returns:
 A valid SlimMPSCNNConvolution object or nil, if failure.
 */
-(id)initWithKernel:(uint)kWidth
       kernelHeight: (uint)kHeight
inputFeatureChannels: (uint)iFeatureChannels
outputFeatureChannels:(uint)oFeatureChannels
       neuronFilter: (MPSCNNNeuron*)spurFilter
             device: (id<MTLDevice>)device
         kernelName: (NSString*)kName
        inDirectory: (NSString*)inDir
            padding: (BOOL)pad
            strideX: (uint)strX
            strideY: (uint)strY
destinationFeatureChannelOffset: (uint)destFeatureChannelOffset
           groupNum: (uint)gNum;

-(void)encodeToCommandBuffer: (id<MTLCommandBuffer>)cmdbuffer sourceImage: (MPSImage*)src destinationImage: (MPSImage*)dst;

@end
