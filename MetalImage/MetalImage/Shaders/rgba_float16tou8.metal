//
//  rgba_float16tou8.metal
//  MetalVideoFilter
//
//  Created by xuqing on 2022/1/27.
//  Copyright © 2022 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


half3 ycbcr2rgb(half3 ycbcr)
{
    half3x3 mat(half3(1.h,          1.h,            1.h),
                half3(0.h,          -0.18732h,      1.8556h),
                half3(1.57481h,     -0.46813h,      0.h));
    ycbcr.yz  = ycbcr.yz - half2(0.5h, 0.5h);
    return mat * ycbcr.xyz;
}

constexpr sampler Sampler_ConvertYCbCrData2RGBA(coord::normalized, filter::linear, address::clamp_to_zero);
kernel void convertYCbCr2RGBA(texture2d<half, access::sample> YTexture [[texture(0)]],
                                  texture2d<half, access::sample> CbCrTexture [[texture(1)]],
                                  texture2d<half, access::write> outTexture [[texture(2)]],
                                    uint2 gid [[thread_position_in_grid]])
{

    if(gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height())
    {
        return;
    }
    
    const float2 p = float2((float)gid.x / (float)outTexture.get_width(), (float)gid.y / (float)outTexture.get_height());
    
    half4 rgba(1.0h);
    half3 YCbCr = half3(YTexture.sample(Sampler_ConvertYCbCrData2RGBA, p).x/255.0,
                        CbCrTexture.sample(Sampler_ConvertYCbCrData2RGBA, p).rg);
    
    rgba.xyz = ycbcr2rgb(YCbCr);
    
    outTexture.write(rgba, gid);
}
