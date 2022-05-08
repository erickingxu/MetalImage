//
//  MetalImageDeCNN.h
//  MetalImage
//
//  Created by xuqing on 2022/1/26.
//  Copyright © 2022 erickingxu. All rights reserved.
//

#ifndef MetalImageDeCNN_h
#define MetalImageDeCNN_h
#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>


API_AVAILABLE(ios(11.0))
@interface DeConv2dWrapper : MPSCNNConvolutionTranspose
{
}

-(id)initWithDevice:(id<MTLDevice>)device
    kernelParamName:(NSString*)pname
         kernelSize:(CGSize)kernelsize
inputFeatureChannels:(uint)inFeatureChannelNum
     neuroActivator:(MPSCNNNeuron*)spurActivator
            padding:(CGSize)paddingsize
            strideSize:(CGSize)stridesize
outputFeatureChannels:(uint)outFeatureChannelNum
outputFeatureChannelOffset:(uint)dstFeatureChannelOffset
         byGroupNum:(uint)groupNum;


-(void)encodeFrom:(MPSImage*)src
    toDestination:(MPSImage*)dst
withCommandBuffer:(id<MTLCommandBuffer> )cmdbuffer;

@end



#endif /* MetalImageDeCNN_h */
