//
//  MetalImageMpsCnn.h
//  MetalImage
//
//  Created by erickingxu on 22/3/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//
#import <Accelerate/Accelerate.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface MPTensor : NSObject<MPSCNNConvolutionDataSource>
@property (nonatomic) float16_t *cpu_data;
@property (nonatomic) unsigned int bytesSize;
@property (nonatomic) int W;
@property (nonatomic) int H;
@property (nonatomic) int C;
@property (nonatomic) int N;
@property (nonatomic) MPSImage* gpu_data;

@property float* weights_;
@property float* bias_;
@property MPSCNNConvolutionDescriptor* desc_;

-(void)syncTensorToGPU:(id<MTLDevice>)mps_device;
-(void)syncTensorToCPU;
- (id)initWithWeight:(float*)weights
                bias:(float*)bias
                desc:(MPSCNNConvolutionDescriptor*)desc ;
@end
