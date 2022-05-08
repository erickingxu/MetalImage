//
//  MetalImageBaseCNN.h
//  MetalImage
//
//  Created by xuqing on 2022/1/26.
//  Copyright © 2022 erickingxu. All rights reserved.
//

#ifndef MetalImageBaseCNN_h
#define MetalImageBaseCNN_h

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

//using wrapper class for processing data loading and base params producing
@interface Conv2dWrapper : MPSCNNConvolution
{
    BOOL padding;
}

-(id)initWithDevice:(id<MTLDevice>)device
    kernelParamName:(NSString*)pname
         kernelSize:(CGSize)kernelsize
inputFeatureChannels:(uint)inFeatureChannelNum
     neuroActivator:(MPSCNNNeuron*)spurActivator
            padding:(BOOL)is_paded
            strideSize:(CGSize)stridesize
outputFeatureChannels:(uint)outFeatureChannelNum
outputFeatureChannelOffset:(uint)dstFeatureChannelOffset
         byGroupNum:(uint)groupNum;


-(void)encodeFrom:(MPSImage*)src
    toDestination:(MPSImage*)dst
withCommandBuffer:(id<MTLCommandBuffer> )cmdbuffer;

@end
#endif /* MetalImageBaseCNN_h */
