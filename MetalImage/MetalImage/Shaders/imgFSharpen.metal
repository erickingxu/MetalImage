//
//  imgFSharpen.metal
//  MetalImage
//
//  Created by ericking on 8/8/2017.
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

/////faceBuf<float> [eyeL,eyeR, cntL0, cntR0, radius0, delta0 ,cntL1, cntR1, radius1, delta1, cntL2, cntR2, radius2, delta2, cntL3, cntR3, radius3, delta3]

kernel void faceSharpen(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                        texture2d<half, access::write> outTexture  [[ texture(1) ]],
                        device float*                  faceBuf     [[buffer(0)]],
                        uint2                          gid         [[ thread_position_in_grid ]])
{
    half tx = half(gid.x)/half(inTexture.get_width());
    half ty = half(gid.y)/half(inTexture.get_height());
    
//    float face_width = distance(eyeL, eyeR);
//    half2 positionToTransformed(tx, ty);
//    half4 radius(0.125,0.125,0.125,0.125);
//    float aspectRatio = inTexture.get_width() / inTexture.get_height();
//
//    for(int i = 0; i < 4; i++)
//    {
//        positionToTransformed = oldPositionBeforeWraped(positionToUse, leftContourPoints[i], rightContourPoints[i], radius[i], deltaArray[i] * face_width, aspectRatio);
//        positionToTransformed = oldPositionBeforeWraped(positionToTransformed, rightContourPoints[i], leftContourPoints[i], radius[i], deltaArray[i] * face_width, aspectRatio);
//    }
//    uint gid_x = positionToTransformed.x * inTexture.get_width();
//    uint gid_y = positionToTransformed.y * inTexture.get_height();
//    uint2 gid_new(gid_x, gid_y);
    
    half4 inColor  = half4(0.0, 1.0, 0.0, 1.0);//inTexture.read(gid_new);//
    outTexture.write(inColor, gid);
}
