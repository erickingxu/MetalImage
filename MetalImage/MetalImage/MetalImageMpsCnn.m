//
//  MetalImageMpsCnn.m
//  MetalImage
//
//  Created by erickingxu on 22/3/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#import "MetalImageMpsCnn.h"
#import <Foundation/Foundation.h>
#include <sys/mman.h>

#include "MetalImageMpsCnn.h"

@implementation MPTensor
{
    int data_num;
    int components_num;
    int slice_ptr_offset;
    int row_bytes_num;
    int slices_per_batch;
    int slices_num;
    MTLRegion  gpu_data_region;
}

-(void)syncTensorToGPU:(id<MTLDevice>)mps_device{
    if (mps_device && _cpu_data) {
        if (nil == _gpu_data) {
            _gpu_data = [[MPSImage alloc] initWithDevice:mps_device imageDescriptor:[MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width:_W height:_H featureChannels:_C numberOfImages:_N usage:MTLTextureUsageShaderRead|MTLTextureUsageShaderWrite]];
            gpu_data_region = MTLRegionMake3D(0, 0, 0, _W, _H, 1);
        }
        float16_t *tmp = (float16_t*)calloc(slice_ptr_offset, sizeof(float16_t));
        for (int s=0; s<slices_num; s++) {
            float16_t* ptr = _cpu_data + s*slice_ptr_offset;
            int nnum = 1;//std::min( _C, components_num);
            for (int c = 0; c<nnum; c++) {
                for (int y=0; y<_H; y++) {
                    for (int x=0; x<_W; x++) {
                        tmp[components_num*(y*_W+x) + c] = *ptr++;
                    }
                }
            }
            [_gpu_data.texture replaceRegion:gpu_data_region mipmapLevel:0 slice:s withBytes:tmp bytesPerRow:row_bytes_num bytesPerImage:0];
        }
        free(tmp);
    }
    else{
        NSAssert(false, @"no cpu data or right gpu device for sync tensor!!!");
    }
}

-(void)syncTensorToCPU{
    if (_gpu_data) {
        if (!_cpu_data) {
            _cpu_data = (float16_t*) calloc(data_num, sizeof(float16_t));
        }
        float16_t *tmp = (float16_t*)calloc(slice_ptr_offset, sizeof(float16_t));
        for (int s=0; s<slices_num; s++) {
            [_gpu_data.texture getBytes:tmp bytesPerRow:row_bytes_num bytesPerImage:0 fromRegion:gpu_data_region mipmapLevel:0 slice:s];
            float16_t* cpu_ptr = _cpu_data +s*slice_ptr_offset;
            int cnt = 0;
            for (int elmt = 0; elmt < components_num; elmt++) {
                int chnl = s*components_num+ elmt;
                if (chnl < _C) {
                    for (int y = 0; y<_H; y++) {
                        for (int x=0; x<_W; x++) {
                            cpu_ptr[cnt++] = tmp[components_num*(y*_W + x) + elmt];
                        }
                    }
                }else{
                    break;
                }
            }//elements for loop end
        }//slice forloop end
        free(tmp);
    }else{
        NSAssert(false, @"no gpu data for export data ,please check it !");
    }
}

- (id)initWithWeight:(float*)weights
                bias:(float*)bias
                desc:(MPSCNNConvolutionDescriptor*)desc {
    if(self = [super init]){
   
        [self setDesc_:desc];
        [self setWeights_:weights];
        [self setBias_:bias];
        return self;
    }
    return Nil;
}
- (float*)biasTerms {
  return self.bias_;
}
-(void*)weights{
    return  self.weights_;
}
- (MPSDataType)dataType {
  return MPSDataTypeFloat32;
}
- (MPSCNNConvolutionDescriptor*)descriptor {
  return self.desc_;
}
- (NSString*)label {
  return Nil;
}
- (BOOL)load {
  return true;
}
- (float*)lookupTableForUInt8Kernel {
  return NULL;
}
- (void)purge {
  return;
}
- (vector_float2*)rangesForUInt8Kernel {
  return NULL;
}

- (id)copyWithZone:(NSZone*)zone {
  MPTensor* newDataSource = [[self class] allocWithZone:zone];
  newDataSource.weights_ = self.weights_;
  newDataSource.bias_ = self.bias_;
  newDataSource.desc_ = self.desc_;
  return newDataSource;
}
@end
