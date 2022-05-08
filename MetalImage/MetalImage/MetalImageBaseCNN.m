//
//  MetalImageBaseCNN.m
//  MetalImage
//
//  Created by xuqing on 2022/1/26.
//  Copyright © 2022 erickingxu. All rights reserved.
//
#import "MetalImageMpsCnn.h"
#import "MetalImageBaseCNN.h"

@implementation Conv2dWrapper{
    int stride_x;
    int stride_y;
    int kernel_height;
    int kernel_width;
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
         byGroupNum:(uint)groupNum{
    
    padding = is_paded;
  
    int bias_size = outFeatureChannelNum *sizeof(float);
    int weights_size = inFeatureChannelNum * kernelsize.width * kernelsize.height * outFeatureChannelNum * sizeof(float);
    //crete conv descriptors from stride and etc.
    MPSCNNConvolutionDescriptor* conv_descr = [MPSCNNConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelsize.width kernelHeight:kernelsize.height inputFeatureChannels:inFeatureChannelNum outputFeatureChannels:outFeatureChannelNum neuronFilter:spurActivator];
    
    conv_descr.strideInPixelsX = stridesize.width;
    conv_descr.strideInPixelsY = stridesize.height;
    
    stride_x = stridesize.width;
    stride_y = stridesize.height;
    kernel_height = kernelsize.height;
    kernel_width = kernelsize.width;
    
    if (groupNum > 0) {
        conv_descr.groups = groupNum;
    }
    else{
        NSLog(@"mps convolution must has one group....");
    }

    //load and init bias and weights for conv
  
    //NSBundle* res_bundle =[NSBundle bundleWithPath: [[NSBundle mainBundle] pathForResource:@"BW" ofType:@"bundle"]];
    if([pname isEqualToString:@"down0_conv"]){
        float weight_down_bgr[432] = {0.0887,  0.0338,  0.1870, -0.1103,  0.0943,  0.0471,  0.0744,  0.0921,
            -0.0409,  0.2218,  0.1209, -0.0122, -0.1344, -0.1046, -0.0325,  0.3472,
             0.0285, -0.0418, -0.0992,  0.0523,  0.0343,  0.1438,  0.2040,  0.1771,
             0.3246,  0.2909,  0.3355,  0.1301,  0.0577,  0.1424, -0.1490,  0.0494,
            -0.0141,  0.1449,  0.1297,  0.1456,  0.1131,  0.0109,  0.0801,  0.3420,
             0.5270,  0.2007, -0.0713, -0.0978, -0.2631, -0.0078,  0.1529, -0.0378,
            -0.1751,  0.0223,  0.0085,  0.0103,  0.0326, -0.0037,  0.1009,  0.2346,
             0.0370,  0.1347, -0.0781,  0.0374, -0.0240, -0.0938,  0.0338, -0.1481,
             0.0171,  0.1234,  0.3506,  0.1890,  0.4085,  0.1517, -0.2095,  0.2929,
             0.0328, -0.0220, -0.0655,  0.2276,  0.0589,  0.1993,  0.0861, -0.2888,
            -0.1565, -0.0833,  0.0837, -0.1013,  0.0168, -0.1572,  0.1640,  0.0690,
             0.0474, -0.1509,  0.0585,  0.0058,  0.0838, -0.1874, -0.1713,  0.1428,
            -0.1884, -0.1527, -0.2180,  0.1132,  0.0248, -0.1979,  0.0159,  0.0830,
             0.3119,  0.2654,  0.0201,  0.0420,  0.2778,  0.3651,  0.0282,  0.0230,
            -0.0501,  0.0522,  0.1647,  0.0299,  0.2895,  0.3486, -0.0506,  0.1206,
             0.6856,  0.4232,  0.2934,  0.3901,  0.5196,  0.5079,  0.0465,  0.1096,
             0.2840,  0.6206,  0.8377,  0.8997,  0.0123, -0.0231,  0.3924,  0.1636,
             0.0283,  0.0646,  0.0189, -0.1715, -0.1886, -0.0356,  0.0456, -0.0535,
            -0.2166, -0.0196, -0.0870, -0.2225,  0.1021,  0.0491, -0.1331,  0.2221,
             0.3514,  0.0501,  0.0599,  0.0428, -0.0875,  0.3236,  0.0431,  0.0414,
             0.1414,  0.2754, -0.0149,  0.0125,  0.0709,  0.1024,  0.0246,  0.0897,
            -0.0597,  0.0132, -0.1855, -0.0357,  0.1103, -0.0064,  0.0140,  0.2861,
            -0.0358,  0.2497,  0.3827,  0.2667, -0.1252, -0.0378, -0.1283, -0.0964,
            -0.1818, -0.2407,  0.2107,  0.3245, -0.0615, -0.0415,  0.2138, -0.0152,
             0.1018, -0.1286,  0.0639, -0.1462,  0.0635,  0.1859, -0.0419, -0.2172,
            -0.0948,  0.1838,  0.2073,  0.1093, -0.0864, -0.2714, -0.2963, -0.1105,
             0.0894,  0.1166,  0.0193, -0.0991,  0.1316,  0.1459,  0.1185,  0.3870,
             0.1482, -0.1317, -0.0687, -0.1066, -0.0342,  0.0805, -0.1061,  0.0904,
            -0.1173,  0.1640,  0.1823,  0.1090,  0.1131,  0.5030,  0.3855,  0.0186,
            -0.0495, -0.1790, -0.1380, -0.0985, -0.1006, -0.0110,  0.4183,  0.1850,
            -0.0870, -0.0172,  0.0720,  0.0168,  0.0037,  0.0497, -0.0040,  0.1648,
            -0.0821,  0.0852,  0.0154,  0.0745, -0.1808, -0.1531, -0.0151, -0.1998,
             0.0228, -0.1284,  0.0930,  0.1950,  0.2271,  0.1844,  0.1337, -0.0901,
             0.1644,  0.1130,  0.3268, -0.3005, -0.0251, -0.2923,  0.0184,  0.0673,
             0.0236,  0.0724,  0.0329,  0.0632, -0.0466, -0.0256, -0.0187,  0.1355,
             0.1395, -0.0557,  0.0661,  0.1781,  0.2562,  0.0141, -0.0153,  0.2776,
            -0.0285,  0.0051,  0.1771, -0.0629, -0.2671, -0.1504, -0.1164,  0.0467,
            -0.0388,  0.1580, -0.0526, -0.1298, -0.0228,  0.1600,  0.0484,  0.0932,
             0.2050,  0.3440,  0.1589,  0.3265,  0.1881,  0.1922,  0.1478,  0.3675,
             0.3665,  0.2584,  0.3758,  0.0225, -0.1375,  0.0197,  0.0804, -0.0610,
             0.1954,  0.1358,  0.2631,  0.2858,  0.0645, -0.0404,  0.0458,  0.0120,
             0.0728,  0.2462,  0.0400,  0.0876,  0.0306, -0.0259,  0.0055,  0.0806,
             0.1674,  0.2745,  0.1632,  0.1683,  0.3521, -0.0444,  0.1532,  0.2540,
             0.0796,  0.3935,  0.3391,  0.1914,  0.4305,  0.2729,  0.2602, -0.0349,
             0.0163, -0.0411, -0.1174, -0.1615, -0.2280,  0.0250,  0.2316,  0.0638,
             0.0822, -0.0390, -0.0132,  0.2815,  0.1050, -0.0293,  0.3915,  0.0495,
             0.0763, -0.0194, -0.2102, -0.0760,  0.1587, -0.1409, -0.1813,  0.1665,
             0.0437,  0.0548,  0.1265,  0.1259,  0.0749,  0.1132, -0.0214, -0.1441,
             0.0550,  0.0690,  0.1669, -0.2931, -0.0415,  0.0602,  0.2372,  0.2023,
            -0.0933, -0.1678,  0.0151,  0.1483, -0.0261, -0.1162, -0.0547,  0.4465,
             0.3148, -0.1100,  0.1396,  0.0341,  0.0091, -0.1430,  0.0458,  0.0781,
            -0.0057,  0.0735, -0.0786, -0.0677, -0.0782,  0.1284,  0.2520,  0.2357,
            -0.0426, -0.0305, -0.2103, -0.3391, -0.0066, -0.0803, -0.0060, -0.0944,
            -0.2708, -0.0383,  0.2668,  0.3400,  0.1636, -0.2416, -0.0365, -0.0646
        };
        float bias_down_bgr[16]={-0.0144, -0.0756, -0.0182,  0.3199, -0.4325,  0.3934,  0.5689,  0.5780,
            -0.0075,  0.4192,  0.6274, -0.2219, -0.2209,  0.3880,  0.1327,  0.4450};
       
        float weight_down0[72] = {3.2186e+01, -8.6636e+01,  1.5088e+01,  1.4096e+01, -1.6556e+02,
            1.2792e+02,  8.2906e+00,  1.7903e+02,  6.3720e+01, -1.3847e+01,
            7.7097e+01, -2.0428e+00,  4.8488e+01, -3.1460e+01,  3.9982e+01,
           -3.6066e+00,  6.0753e+00,  7.6362e+01,  5.3301e+01,  5.4028e+01,
           -2.3631e+01, -6.0314e+00,  3.2745e+01, -1.2489e+02, -1.8819e+01,
           -6.8433e+00,  2.1057e+02,  7.0792e+01, -3.4215e+01,  3.6072e+01,
           -8.1273e+01,  1.5302e+02,  2.3833e+02, -4.9676e+00, -6.0222e+01,
           -5.8656e+01,  6.1530e+01, -4.6791e+01,  8.3035e+01,  6.4416e+00,
            2.3332e+02, -1.6726e+02,  6.4491e+01,  9.0495e+01, -6.6617e+01,
            2.9075e+01, -9.0545e+01,  9.9247e+01, -3.6093e+01,  3.8504e+01,
           -4.3025e+01, -5.8596e+01,  1.2289e+02,  5.2278e+01,  1.1771e+02,
            1.7064e+02, -2.6856e+01, -1.3609e+02,  3.9943e+01, -8.4586e+01,
           -5.4320e+01,  1.4309e+02, -2.0091e+01, -6.4711e+01,  4.6949e+00,
           -3.7060e+01, -2.2215e-01,  2.3968e+02, -5.9535e+01,  1.8239e+01,
            3.0517e+01,  9.8796e+01};
        float bias_down0[16]={ 0.3512,  0.5926, -0.5305,  0.4027,  0.7066,  0.8910,  0.4267, -0.7030};
        MPTensor* data_source = [[MPTensor alloc] initWithWeight:weight_down0
                                  bias:bias_down0
                                  desc:conv_descr];
            
        if (self = [super initWithDevice:device weights:data_source]) {
            self.destinationFeatureChannelOffset = dstFeatureChannelOffset;
            return self;
        }
        return Nil;
    }else{
        return Nil;
    }
    
    return self;
}


-(void)encodeFrom:(MPSImage*)src
    toDestination:(MPSImage*)dst
withCommandBuffer:(id<MTLCommandBuffer> )cmdbuffer{
    MPSOffset mps_offset;
    if (padding) {
//        uint pad_height = (uint)(stride_y* (dst.height -1) + kernel_height - src.height );
//        uint pad_width = (uint)(stride_x* (dst.width -1) + kernel_width - src.width );
//        uint pad_top = pad_height/2;
//        uint pad_left= pad_width/2;
//
//        mps_offset.x = kernel_width/2 - pad_left;
//        mps_offset.y = kernel_height/2 - pad_top;
        //self.edgeMode = MPSImageEdgeModeZero;
    }else{
        mps_offset.x = kernel_width/2 ;
        mps_offset.y = kernel_height/2;
    }
    mps_offset.z = 0;
    //self.offset = mps_offset;
    [super encodeToCommandBuffer:cmdbuffer sourceImage:src destinationImage:dst];
}

@end

