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

@implementation MetalImageMpsCnn
{
    BOOL _padding;
    uint stridePixelsX;
    uint stridePixelsY;
    uint kernelWidth;
    uint kernelHeight;
    
}

-(id)initWithKernel:(uint)kWidth  kernelHeight: (uint)kHeight  inputFeatureChannels: (uint)iFeatureChannels
outputFeatureChannels:(uint)oFeatureChannels
       neuronFilter: (MPSCNNNeuron*)spurFilter
             device: (id<MTLDevice>)device
         kernelName: (NSString*)kName
        inDirectory: (NSString*)inDir
            padding: (BOOL)pad
            strideX: (uint)strX
            strideY: (uint)strY
destinationFeatureChannelOffset: (uint)destFeatureChannelOffset
           groupNum: (uint)gNum
{
    _padding = pad;
    stridePixelsX = strX;
    stridePixelsY = strY;
    kernelWidth   = kWidth;
    kernelHeight  = kHeight;
    int sizeBias = oFeatureChannels * sizeof(float);
    int sizeWeights = iFeatureChannels * kernelHeight * kernelWidth * oFeatureChannels * sizeof(float);
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Ps" ofType:@"bundle"];
    NSBundle *resBundle = [NSBundle bundleWithPath:bundlePath];
    
    NSString* wtPath = [[NSString alloc] initWithFormat:@"%@/%@%@_weight",inDir,inDir,kName];
    NSString* bsPath = [[NSString alloc] initWithFormat:@"%@/%@%@_bias",inDir,inDir,kName];
    NSString* weightStr = [resBundle pathForResource:wtPath ofType:@".dat" inDirectory:@"prisma"];
    NSString* biasStr = [resBundle pathForResource:bsPath ofType:@".dat" inDirectory:@"prisma"];
    int fd_w = open([weightStr UTF8String], O_RDONLY, S_IRUSR|S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
    int fd_b = open([biasStr UTF8String],  O_RDONLY, S_IRUSR|S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
    assert(fd_w != -1);
    assert(fd_b != -1);
    void* hdrW = mmap(NULL, sizeWeights, PROT_READ, MAP_FILE | MAP_SHARED, fd_w, 0);
    void* hdrB = mmap(NULL, sizeBias, PROT_READ, MAP_FILE | MAP_SHARED, fd_b, 0);
    
    // create appropriate convolution descriptor with appropriate stride
    MPSCNNConvolutionDescriptor *cnndescr = [MPSCNNConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelWidth kernelHeight:kernelHeight inputFeatureChannels:iFeatureChannels outputFeatureChannels:oFeatureChannels neuronFilter:spurFilter];
    cnndescr.strideInPixelsX = strX;
    cnndescr.strideInPixelsY = strY;
    assert(gNum > 0);// "group size must be >= 1"
    cnndescr.groups = gNum;
    
    if(self = [super initWithDevice:device convolutionDescriptor:cnndescr kernelWeights:(float*)hdrW biasTerms:(float *)hdrB flags:MPSCNNConvolutionFlagsNone])
    {
        self.destinationFeatureChannelOffset = destFeatureChannelOffset;
    }
    close(fd_w);
    close(fd_b);
    return self;
}

-(void)encodeToCommandBuffer: (id<MTLCommandBuffer>)cmdbuffer sourceImage: (MPSImage*)src destinationImage: (MPSImage*)dst
{
    MPSOffset mpsoffset;
    
    if (_padding)
    {
        uint pad_along_height = (uint)((dst.height - 1)*stridePixelsY + kernelHeight - src.height);
        uint pad_along_width  = (uint)((dst.width - 1)*stridePixelsX + kernelWidth - src.width);
        uint pad_top          = pad_along_height/2;
        uint pad_left         = pad_along_width/2;
        mpsoffset.x = kernelWidth/2 - pad_left;
        mpsoffset.y = kernelHeight/2 - pad_top;
        mpsoffset.z = 0;
        
    }
    else
    {
        mpsoffset.x = kernelWidth/2;
        mpsoffset.y = kernelHeight/2;
        mpsoffset.z = 0;
        
        
    }
    self.offset = mpsoffset;
    [super encodeToCommandBuffer:cmdbuffer sourceImage:src destinationImage:dst];
}

@end
