//
//  imgToneCurve.metal
//  MetalImage
//
//  Created by ericking on 23/7/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void imgToneCurve(
                        texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        device float *curveBuffer [[buffer(0)]],
                        uint2 gid [[thread_position_in_grid]]
                        )
{
    const float4 inColor = inTexture.read(gid);
    unsigned int rvalue = (inColor.r * 256 > 255)? 255 : (inColor.r * 256);
    unsigned int gvalue = (inColor.g * 256 > 255)? 255 : (inColor.g * 256);
    unsigned int bvalue = (inColor.b * 256 > 255)? 255 : (inColor.b * 256);
    
    float  b = *(curveBuffer + bvalue*3);
    float  g = *(curveBuffer + gvalue*3+1);
    float  r = *(curveBuffer + rvalue*3+2);
    
    const float4 outColor = float4(r , g, b, inColor.a);
    outTexture.write(outColor, gid);
}
