//
//  imgFSharpen.metal
//  MetalImage
//
//  Created by ericking on 8/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float2 oldPositionBeforeWraped(float2 txtCoord, float2 cntrPostionU, float2 cntrPostionX, float radius, float delta, float aspect)
{
    float2 oldPostion = txtCoord;//for everyone first
    float r = distance(txtCoord, cntrPostionU);
    if(r < radius)
    {
        float2 dir   = normalize(cntrPostionX-cntrPostionU);
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
    float eyeLx =  *faceBuf, eyeLy = *(faceBuf+1);
    float eyeRx =  *(faceBuf+2), eyeRy = *(faceBuf+3);
    faceBuf += 3;
    float2 eyeL(eyeLx, eyeLy);
    float2 eyeR(eyeRx, eyeRy);
    
    float2 leftContourPoints[4];
    float2 rightContourPoints[4];
    float  radius[4];
    float  delta[4];
    
    for(int k = 0; k < 4; k++)
    {
        leftContourPoints[k].x =  *(faceBuf+ 5*k), leftContourPoints[k].y = *(faceBuf + 5*k + 1 );
        rightContourPoints[k].x =  *(faceBuf + 5*k + 2), rightContourPoints[k].y = *(faceBuf + 5*k + 3);
        radius[k] =  *(faceBuf + 5*k + 4), delta[k] = *(faceBuf + 5*k + 5);
    }
    half tx = half(gid.x)/half(inTexture.get_width());
    half ty = half(gid.y)/half(inTexture.get_height());
    
    float face_width = distance(eyeL, eyeR);
    float2 positionToTransformed(tx, ty);

    float aspectRatio = inTexture.get_width() / inTexture.get_height();

    for(int i = 0; i < 4; i++)
    {
        positionToTransformed = oldPositionBeforeWraped(positionToTransformed, leftContourPoints[i], rightContourPoints[i], radius[i], delta[i] * face_width, aspectRatio);
        positionToTransformed = oldPositionBeforeWraped(positionToTransformed, rightContourPoints[i], leftContourPoints[i], radius[i], delta[i] * face_width, aspectRatio);
    }
    uint gid_x = positionToTransformed.x * inTexture.get_width();
    uint gid_y = positionToTransformed.y * inTexture.get_height();
    uint2 gid_new(gid_x, gid_y);
    
    half4 inColor  = half4(0.0, 1.0, 0.0, 1.0);//inTexture.read(gid_new);//
    outTexture.write(inColor, gid);
}
