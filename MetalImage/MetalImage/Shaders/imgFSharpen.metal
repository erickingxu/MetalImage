//
//  imgFSharpen.metal
//  MetalImage
//
//  Created by xuqing on 8/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

half2 oldPositionBeforeWraped(half2 txtCoord, half2 cntrPostionU, half2 cntrPostionX, float radius, float delta, float aspect)
{
    half2 oldPostion = txtCoord;//for everyone first
    float r = distance(txtCoord, cntrPostionU);
    if(r < radius)
    {
        half2 dir   = normalize(cntrPostionX-cntrPostionU);
        float dist  = pow(radius,2.0) - pow(r, 2.0);
        float sigma = dist/(dist + pow( r-delta ,2.0));
        oldPostion  = oldPostion - pow(sigma, 2.0)*delta*dir;//delta for accuracy wrap
    }
    return oldPostion;
}


kernel void faceSharpen(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                     texture2d<half, access::write> outTexture  [[ texture(1) ]],
                     uint2                          gid         [[ thread_position_in_grid ]])
{
    half4 inColor  = inTexture.read(gid);//half4(0.0, 1.0, 0.0, 1.0);//
    outTexture.write(inColor, gid);
}
