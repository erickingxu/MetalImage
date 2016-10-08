//
//  imgSaturation.metal
//  MetalImage
//
//  Created by xuqing on 25/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);
kernel void imgSaturation(
                       texture2d<half, access::read> inTexture [[texture(0)]],
                       texture2d<half, access::write> outTexture [[texture(1)]],
                       device float *saturation [[buffer(0)]],
                       uint2 gid [[thread_position_in_grid]]
                       )
{
    const half4 inColor = inTexture.read(gid);
    const half luminance = dot(inColor.rgb, kRec709Luma);
    const half3 greyScaleColor = half3(luminance);
    half3 alpha  = half3(*saturation, *(saturation+1), *(saturation+2));
    const half4 outColor = half4(mix(greyScaleColor,inColor.rgb, alpha),inColor.a);
    outTexture.write(outColor, gid);
}


