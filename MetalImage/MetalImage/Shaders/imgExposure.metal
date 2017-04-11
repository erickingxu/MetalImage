//
//  imgExposure.metal
//  MetalImage
//
//  Created by erickingxu on 25/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//


#include <metal_stdlib>
using namespace metal;
kernel void exposure(
                     texture2d<half, access::read> inTexture [[texture(0)]],
                     texture2d<half, access::write> outTexture [[texture(1)]],
                     device float *exposure [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]])
{
    const half4 inColor = inTexture.read(gid);
    const half4 outColor(inColor.rgb * half3(pow(2.0, *exposure)),inColor.a);
    outTexture.write(outColor, gid);
}


