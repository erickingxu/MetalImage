//
//  MetalImageDeCNN.m
//  MetalImage
//
//  Created by xuqing on 2022/1/26.
//  Copyright © 2022 erickingxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalImageMpsCnn.h"
#import "MetalImageDeCNN.h"

@implementation DeConv2dWrapper{
    int stride_x;
    int stride_y;
    int kernel_height;
    int kernel_width;
    BOOL padding;
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
         byGroupNum:(uint)groupNum{
    //crete conv descriptors from stride and etc.
    MPSCNNConvolutionDescriptor* deconv_descr = [MPSCNNConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelsize.width kernelHeight:kernelsize.height inputFeatureChannels:inFeatureChannelNum outputFeatureChannels:outFeatureChannelNum neuronFilter:spurActivator];
    
    deconv_descr.strideInPixelsX = stridesize.width;
    deconv_descr.strideInPixelsY = stridesize.height;
    
    stride_x = stridesize.width;
    stride_y = stridesize.height;
    kernel_height = kernelsize.height;
    kernel_width = kernelsize.width;
    
    if (groupNum > 0) {
        deconv_descr.groups = groupNum;
    }
    else{
        NSLog(@"mps convolution must has one group....");
    }
    if (paddingsize.width> 0 || paddingsize.height>0) {
        padding = YES;
    }
    //load and init bias and weights for conv
  
    //NSBundle* res_bundle =[NSBundle bundleWithPath: [[NSBundle mainBundle] pathForResource:@"BW" ofType:@"bundle"]];
    if([pname isEqualToString:@"up0_deconv"]){
        float weight_up_bgr[768] = {
            8.0065e-02,  1.0608e-01, -1.4677e-02,  9.4670e-02,  2.0383e-02,
                     1.6146e-01,  7.4697e-02, -8.8356e-02, -3.8739e-02,  6.4799e-02,
                     1.8694e-02, -8.4880e-02, -1.2207e-01, -9.6248e-02,  1.2870e-01,
                    -1.0928e-01, -2.9061e-02, -1.5889e-01,  7.6718e-02,  6.3713e-02,
                    -9.7225e-02, -7.9874e-02, -6.4101e-03, -6.7274e-02, -1.3293e-01,
                    -1.4831e-02,  1.8598e-01, -1.8472e-02,  1.9548e-01, -1.4618e-01,
                     1.9754e-01, -2.1152e-02,  4.8235e-02,  4.2048e-02, -3.9895e-02,
                     8.9208e-02,  2.6119e-02, -7.6954e-02, -1.0610e-01, -7.1755e-02,
                    -1.0946e-01,  2.8112e-02,  1.5837e-02,  6.3517e-02, -9.4613e-02,
                     7.6071e-02,  1.2708e-01, -8.6570e-02,  1.0916e-01,  5.8985e-02,
                     6.5272e-02,  2.4120e-02, -2.8431e-02,  1.4507e-02,  4.0084e-02,
                    -6.5248e-02,  1.6227e-03,  1.1582e-01, -4.6143e-02,  6.1499e-02,
                    -9.3806e-02, -8.0109e-02,  3.4974e-02, -7.6253e-02,  2.7158e-01,
                    -3.4405e-02, -1.9255e-01, -5.9004e-02,  2.9212e-02, -2.8904e-01,
                    -1.7429e-02, -9.1223e-03,  2.3723e-01, -1.1771e-01,  6.0274e-02,
                     1.4427e-01, -1.9915e-01,  4.8136e-02, -2.3633e-01,  2.7513e-01,
                    -1.5806e-01,  3.0162e-01,  2.8965e-01, -3.2418e-01,  2.4597e-02,
                    -3.1645e-01, -4.8157e-02,  2.3087e-01,  2.9470e-01, -2.1217e-01,
                     1.9988e-01, -7.6663e-02,  1.3442e-01,  3.0546e-01,  8.6769e-02,
                    -1.7289e-01,  2.5048e-01, -2.9538e-01,  2.0162e-01, -2.1589e-01,
                    -1.4039e-02, -1.1736e-01,  2.4735e-01, -1.8906e-01, -1.4196e-01,
                     1.6568e-01, -2.4393e-02, -2.7608e-02,  1.9587e-01,  3.0638e-01,
                    -1.3719e-01, -1.1561e-01,  1.7834e-01, -1.0926e-02, -6.6958e-02,
                     3.0427e-02,  1.3432e-02, -2.5609e-01,  3.9245e-02,  9.5297e-02,
                     4.6055e-02,  1.7784e-02,  3.6027e-02, -1.6258e-01,  4.4857e-03,
                    -6.6897e-03,  5.3986e-02, -3.1968e-02, -4.4108e-03,  4.5876e-02,
                     1.0501e-01,  1.4303e-01,  2.5200e-02,  3.6302e-02, -1.1949e-01,
                    -8.7503e-02, -2.3269e-01,  1.6322e-02,  7.8662e-02, -1.0755e-01,
                     1.4401e-01,  8.3038e-02, -1.6822e-01, -1.5192e-01,  5.2597e-02,
                    -3.0441e-01,  1.4455e-01,  4.6844e-02,  1.6432e-01, -1.4701e-01,
                    -1.7651e-01,  3.4652e-02,  7.6810e-02,  9.9625e-02, -2.9290e-01,
                    -3.1980e-01,  2.9583e-01,  1.7893e-01,  2.5459e-01,  2.9710e-01,
                     3.9660e-01, -1.3641e-01, -3.6231e-02,  2.6566e-01, -8.4069e-02,
                    -8.8541e-02,  1.3544e-01,  1.0418e-01, -8.1549e-02, -2.8075e-01,
                    -6.4603e-02, -9.6076e-02,  2.8473e-01,  2.7601e-01,  8.3897e-02,
                    -2.1541e-01,  6.6080e-03, -6.5747e-02,  9.2010e-02,  6.0585e-02,
                    -1.8775e-02, -3.1394e-02,  3.2077e-02, -1.1542e-01, -2.4021e-02,
                    -5.6429e-03,  6.6671e-02, -3.1960e-02,  1.5729e-02,  8.8458e-02,
                     6.2134e-02, -1.9935e-02,  1.1750e-01,  8.6678e-02,  5.3933e-02,
                     2.4911e-02,  2.1985e-02,  4.3837e-04,  6.3479e-02,  7.4086e-02,
                    -2.0850e-02,  8.8528e-02, -6.7775e-02, -5.7176e-02, -5.9561e-02,
                     2.0678e-02, -1.6892e-01, -5.3794e-02,  1.1057e-02, -5.0448e-02,
                     1.5455e-02, -1.9916e-01, -1.5790e-02, -1.1480e-01, -2.6490e-02,
                     1.8592e-03, -6.7808e-02, -7.3285e-02,  9.8338e-02, -6.5731e-02,
                     3.8254e-03,  8.0391e-02,  1.2946e-01,  1.2147e-01,  6.4109e-02,
                    -1.1152e-02,  4.4735e-02,  9.1852e-02,  6.9874e-03, -6.7893e-02,
                    -2.9073e-04, -1.1630e-02, -7.0246e-02, -4.9560e-02,  1.7020e-02,
                    -5.6449e-02,  3.9942e-02,  8.3036e-02, -4.9424e-02, -1.0147e-01,
                    -3.4704e-02,  2.2884e-03, -4.0868e-02,  4.4671e-02,  1.0642e-02,
                     4.9011e-02,  5.4016e-03, -5.2196e-02, -1.6607e-02, -1.5931e-02,
                     2.1875e-02,  4.6502e-02, -3.6883e-02, -2.8622e-02,  2.4084e-02,
                    -3.1229e-02,  1.3779e-01,  1.7802e-02,  4.2096e-02, -4.8253e-02,
                     6.9121e-02,  2.3101e-02,  3.9429e-02, -2.2271e-03, -1.0257e-01,
                    -4.7017e-02,  4.4799e-02, -1.3471e-01, -1.3654e-01, -1.9115e-02,
                     1.2203e-01, -2.6356e-02,  7.6847e-02,  5.3561e-02, -1.0231e-01,
                    -2.3314e-02, -3.5382e-02, -1.0268e-01,  7.0839e-02, -1.0499e-02,
                    -3.2580e-02,  1.2616e-01,  4.8892e-02, -4.2215e-02,  7.2594e-02,
                    -1.4455e-01,  4.7442e-02, -2.0039e-02, -3.2193e-02,  1.7341e-01,
                    -1.3340e-01, -9.1693e-02,  1.0867e-02,  8.3803e-02, -8.4988e-02,
                     4.2985e-02, -6.8371e-02,  4.3157e-02, -1.2382e-01,  1.1409e-01,
                    -8.0417e-02,  4.4489e-02,  1.4335e-02,  8.6063e-02, -2.2551e-02,
                    -4.0612e-03,  7.2326e-03, -2.3483e-02,  7.7049e-02, -4.1928e-02,
                    -8.8308e-03,  7.4055e-02, -9.8500e-02, -5.2649e-02, -1.6249e-02,
                     1.7858e-02, -1.1271e-01,  1.3405e-02,  1.7120e-02,  1.4944e-02,
                     1.5228e-01,  4.7723e-02, -6.9552e-03,  1.4862e-02, -9.0603e-02,
                    -5.1009e-02,  1.0122e-01, -1.7304e-01,  2.2967e-01, -2.1420e-01,
                    -2.2709e-02,  1.9772e-01, -8.9655e-02, -1.6032e-01, -1.5251e-01,
                     3.7298e-01, -2.8204e-01,  4.3597e-01,  4.8258e-02, -1.8624e-01,
                    -2.4941e-02, -1.2353e-01,  2.3152e-01,  6.3149e-02,  5.4973e-01,
                    -9.3632e-02,  1.8775e-01, -3.2826e-02,  1.2055e-01, -6.2452e-02,
                     2.5994e-01, -2.1295e-01,  2.1450e-02, -2.4602e-01, -1.6157e-01,
                    -2.9209e-01, -2.3867e-02,  2.1146e-01,  2.7177e-01, -2.2334e-01,
                     3.6204e-02,  1.5245e-01,  1.0795e-01,  8.3560e-02,  1.7220e-01,
                     8.0246e-02,  1.1021e-01, -4.5632e-02,  5.5560e-02,  8.7755e-02,
                    -6.1833e-02,  2.5975e-02, -3.7774e-02,  2.2038e-02, -2.2814e-02,
                     9.5491e-02,  2.1440e-02, -3.2592e-02, -3.1067e-02, -4.0017e-02,
                     1.0652e-02, -3.9794e-02,  2.8941e-02,  6.3041e-02,  3.4737e-02,
                     7.6790e-02, -2.7842e-02,  7.7078e-02, -6.1501e-03,  9.1992e-02,
                    -4.8346e-02, -9.6810e-02, -8.7245e-02,  1.0556e-01,  8.3026e-02,
                    -8.6448e-02,  9.2795e-02, -5.4082e-02, -5.8236e-02, -1.8395e-01,
                     1.7933e-01,  1.1779e-02, -4.6748e-03,  8.8254e-02,  5.4356e-02,
                     1.6641e-01, -1.9890e-01, -1.8692e-01,  3.3940e-01,  2.5300e-01,
                    -1.2651e-01, -1.9973e-01,  2.3497e-01, -7.4607e-02,  2.0623e-01,
                     4.4292e-01,  3.5268e-01, -1.8515e-02, -2.3502e-01,  7.2730e-02,
                    -1.1808e-01,  1.6622e-01,  2.6610e-01,  1.7623e-01,  1.7145e-01,
                    -1.0388e-01, -1.8072e-01, -2.1571e-02,  2.5049e-01,  4.6053e-04,
                    -2.9513e-02, -1.0689e-01,  5.3062e-02,  9.2032e-02,  1.1339e-02,
                     3.8283e-02, -6.6327e-02,  7.2828e-02, -1.1495e-02, -7.5492e-02,
                     1.3999e-01,  4.0518e-02,  1.1228e-02, -1.0554e-01,  2.3809e-02,
                    -2.3138e-02, -7.4525e-03, -1.2824e-02,  9.3515e-02, -1.8509e-02,
                    -1.2371e-02, -3.0970e-02,  1.0501e-02, -2.8582e-02, -1.1121e-02,
                     3.3953e-02, -7.8065e-02, -1.4760e-01,  1.4641e-01, -5.4812e-02,
                     6.9673e-03,  8.3883e-02,  3.1080e-02,  2.1640e-02,  1.0153e-01,
                     5.8531e-02, -6.5682e-02, -9.1502e-02, -4.1691e-02,  2.1236e-02,
                     6.0509e-04, -1.9623e-02,  2.3739e-02,  4.6179e-02,  1.0319e-01,
                    -1.2656e-02, -5.9056e-02, -1.3373e-02, -1.3146e-02, -2.8543e-02,
                     8.2559e-02,  9.6192e-02, -2.7747e-02,  8.6475e-02, -4.9072e-02,
                     8.8528e-02, -2.2101e-02, -5.4581e-02,  5.2266e-02,  5.1053e-02,
                    -2.5275e-02, -4.3797e-03,  3.0774e-02, -5.0876e-02, -5.7812e-02,
                    -1.3385e-01,  3.8574e-03,  6.0199e-03, -1.2867e-02,  4.2152e-02,
                     7.3965e-02, -1.0015e-01,  7.9612e-03, -2.8034e-02, -2.7694e-02,
                     5.5332e-02, -1.6477e-02, -5.4061e-02, -7.3542e-02,  3.6940e-02,
                    -1.7585e-02, -4.3885e-02,  1.7120e-01,  1.2818e-01,  7.6750e-02,
                    -2.4724e-01, -4.0926e-02,  1.0416e-01,  4.6957e-02,  4.3312e-02,
                    -3.1476e-02,  5.4940e-02, -5.5669e-02, -2.1479e-01,  3.5328e-02,
                     7.0257e-02,  1.4133e-02,  9.2848e-02,  6.3286e-02, -4.8663e-02,
                     9.1466e-02,  1.5966e-01, -4.5405e-02, -7.7359e-02,  1.0585e-01,
                     1.0303e-01, -1.5076e-02,  1.3560e-01, -4.7908e-02,  6.5631e-02,
                    -2.6762e-02, -1.4254e-01, -1.7229e-01, -3.7379e-02, -2.0514e-02,
                     6.7850e-02, -2.6552e-02, -1.3512e-01, -4.2327e-03,  8.7706e-02,
                    -2.5010e-01,  1.3717e-01, -1.3594e-01,  5.2673e-02, -1.5250e-01,
                     2.9970e-01, -1.6942e-01,  9.2806e-02, -2.4506e-03,  6.0365e-02,
                     7.8727e-02,  1.4010e-01, -4.5629e-02, -8.5095e-02,  4.2163e-03,
                    -1.5795e-01,  2.8546e-02,  9.4038e-02, -6.7445e-02,  8.1905e-02,
                    -1.4933e-01,  1.8341e-02, -2.0244e-02,  1.8151e-02,  5.6278e-03,
                    -4.3785e-03,  2.3472e-01,  2.3613e-02,  1.6949e-02, -6.1159e-03,
                    -1.3720e-01, -1.0046e-02, -2.1217e-01, -8.5272e-02,  3.9961e-02,
                    -3.6995e-04,  1.5201e-01,  2.7655e-01, -1.1653e-01, -3.2492e-02,
                     5.5910e-02,  1.6409e-01, -2.9229e-01,  2.3179e-01,  2.9280e-01,
                     2.7992e-01,  2.0628e-02,  3.0316e-03,  1.1095e-02,  1.5170e-01,
                     4.7798e-01,  3.9608e-02,  1.9663e-01,  1.7012e-01, -9.1625e-02,
                    -5.4269e-03, -4.8907e-02, -5.6648e-01, -5.9730e-02, -4.7738e-01,
                     1.5999e-01, -1.5132e-01,  1.0299e-01,  3.2555e-01,  1.7808e-01,
                    -2.1986e-01, -1.6013e-01,  9.7735e-02,  5.5583e-02,  3.7916e-01,
                    -1.9894e-01, -3.1093e-02, -7.9657e-03, -1.9953e-01,  8.7333e-02,
                    -7.1645e-02,  7.6850e-02,  5.2738e-02,  2.4114e-02, -3.8071e-02,
                    -9.5245e-02,  7.2268e-02,  2.9331e-02, -2.7365e-02,  3.3837e-05,
                    -4.9278e-02, -1.1602e-01, -9.5479e-03, -5.1301e-02, -6.7257e-02,
                     9.3374e-02, -5.7764e-02, -2.0826e-02, -5.4375e-02,  1.0304e-01,
                    -1.4287e-02, -1.3179e-01,  1.0952e-01, -1.0143e-01, -1.1942e-02,
                     6.8014e-02, -2.5661e-02, -5.5155e-02, -2.5067e-02, -2.0308e-01,
                    -1.2278e-01,  3.0894e-01, -2.4809e-01,  9.8084e-02,  2.6372e-01,
                     1.8423e-01,  6.5821e-02, -3.4505e-01, -1.9943e-04,  3.4028e-01,
                     2.0201e-01, -1.3305e-01, -2.0699e-02, -6.4664e-02, -9.8973e-02,
                    -4.4977e-02,  1.8050e-01,  2.6886e-01, -3.2972e-01, -8.9860e-02,
                     6.1647e-02, -1.2562e-01,  3.3493e-01, -1.1749e-01,  3.0795e-01,
                     1.4230e-01, -2.8827e-01,  7.3937e-02,  2.3255e-01,  7.6151e-02,
                    -9.9555e-02,  9.5953e-02, -1.3065e-01,  2.5255e-02,  1.6021e-02,
                     9.6492e-02,  6.1143e-02, -5.5696e-02,  8.2793e-02, -1.2193e-01,
                     1.2707e-01,  1.1182e-01,  7.4484e-02,  3.8882e-02,  3.7419e-02,
                    -1.3083e-01, -7.3865e-02, -1.1487e-01, -1.2899e-02,  8.5811e-02,
                     8.1648e-02,  1.3111e-02, -1.8447e-02,  7.3437e-03, -5.6940e-02,
                     3.5986e-02, -8.5928e-02,  1.7979e-02,  4.4102e-02,  2.2173e-02,
                    -8.5928e-02, -5.1597e-02,  2.1352e-02,  2.3549e-02, -1.6025e-02,
                     2.8432e-02, -4.9358e-02,  6.3837e-02,  2.3408e-02, -2.2159e-02,
                     3.4517e-02,  1.1544e-02, -2.5486e-02, -1.2186e-02, -4.9967e-02,
                    -4.1640e-03,  1.0706e-01, -1.6850e-01, -7.4308e-02,  4.9437e-02,
                    -5.9290e-02, -1.1137e-02, -6.3744e-02,  7.6168e-02, -8.5914e-02,
                    -5.0141e-02,  1.2551e-01, -1.0048e-01,  1.0717e-01,  3.2216e-02,
                     2.8995e-03,  3.0458e-02,  1.0995e-01, -4.3702e-02, -8.9374e-02,
                    -7.4800e-02,  2.0057e-02,  2.1015e-02,  2.5933e-02, -7.8620e-02,
                    -2.9521e-02,  9.1133e-03,  1.8988e-02,  3.4526e-02,  7.5881e-02,
                     3.7618e-02,  5.7352e-02, -3.3689e-02, -1.4405e-02,  3.2583e-02,
                    -2.9353e-03, -5.9999e-02,  2.2106e-02
        };
        float bias_up_bgr[3]= { 0.0307, -0.0921, -0.0005};
        float bias_up0= 0.2260;
        float weight_up0[128] = { 0.1127, -0.1537,  0.1279,  0.1428, -0.0471,  0.0890,  0.2916, -0.3793,
            -0.3342,  0.5038,  0.2271, -0.2005, -0.3376, -0.4579,  0.5335, -0.0369,
             0.0015,  0.0089, -0.0483, -0.0233,  0.1358,  0.7842, -0.2891, -0.3227,
             0.0286, -0.0290,  0.2973,  0.0016, -0.0390,  0.2104, -0.1338,  0.0038,
             0.0125,  0.4018,  0.2146, -0.2531,  0.1799, -0.3268, -0.6967, -0.1001,
            -0.8721, -0.0775,  0.3881,  0.6107,  0.6920, -0.0140, -0.3370,  0.7298,
             0.5442,  0.3504, -0.4950,  0.9802, -0.3880, -0.2181, -0.5654,  0.0671,
             0.0824,  0.0886,  0.0082,  0.0468,  0.1435, -0.0701,  0.1490, -0.2756,
             0.1161,  0.1358, -0.0155,  0.0504,  0.1852, -0.5020, -0.1190, -0.1564,
             0.9255, -0.2227, -0.0987, -0.4028,  0.1435,  0.6253,  0.5630,  0.1354,
             0.3761,  0.5636,  0.9640, -0.2881, -0.3736,  0.2904, -0.1608,  0.3290,
             0.0656, -0.0522,  0.0279,  0.0275, -0.0199, -0.0219, -0.0519,  0.0999,
            -0.0070,  0.2143,  0.0453, -0.0422,  0.0268,  0.0106, -0.0569,  0.1224,
            -0.0952,  0.0804, -0.1353, -0.0609, -0.1745,  0.1067, -0.0478, -0.0018,
             0.0629,  0.0140, -0.2419, -0.1289,  0.2309,  0.3269,  0.1325,  0.2209,
            -0.1556,  0.0447, -0.2249,  0.0766, -0.0196,  0.2574,  0.0669, -0.1462};
        
        MPTensor* data_source = [[MPTensor alloc]  initWithWeight:weight_up0  bias:&bias_up0  desc:deconv_descr];
        
        if (self = [super initWithDevice:device weights:data_source]) {
            self.destinationFeatureChannelOffset = dstFeatureChannelOffset;
            return self;
        }
       
    }
   
    return Nil;
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
        
    }else{
        mps_offset.x = kernel_width/2 ;
        mps_offset.y = kernel_height/2;
    }

    if (@available(iOS 11.3, *)) {
        [self encodeToCommandBuffer:cmdbuffer sourceImage:src convolutionGradientState:NULL destinationImage:dst];
    } else {
        // Fallback on earlier versions
        [self encodeFrom:src toDestination:dst withCommandBuffer:cmdbuffer];
    }
}

@end
