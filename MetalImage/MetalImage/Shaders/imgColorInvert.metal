//
//  imgColorInvert.metal
//  MetalImage
//
//  Created by erickingxu on 17/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
kernel void ColorInvert(
                        texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]])
{
    const float4 inColor = inTexture.read(gid);
    const float4 outColor = float4(float3(1.0) - inColor.rgb,inColor.a);
    outTexture.write(outColor, gid);
}


