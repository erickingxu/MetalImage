//
//  imgEyeBig.metal
//  MetalImage
//
//  Created by xuqing on 22/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#define p_eyecenterleft     uLocation0
#define p_eyecenterright    uLocation1
#define p_nose                uLocation2

float2 pointsStretch(float2 textureCoord, float2 originPosition, float2 direction, float radius, float curve)
{
    float infect = distance(textureCoord, originPosition) / radius;
    infect = clamp(1.0 - infect, 0.0, 1.0);
    infect = pow(infect, curve);
    return direction * infect;
}

kernel void eyeSharpen(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                       texture2d<float, access::write> outTexture  [[ texture(1) ]],
                       constant float*                 faceBuf     [[buffer(0)]],
                       uint2                           gid         [[ thread_position_in_grid ]])

{
    float             uBigeyeIntensity = 1.0;
    
    uint2 gid_new(gid.x, gid.y);
    ///get data from faceBuf into loc
    float2 uLocation0  = float2(*faceBuf, *(faceBuf+1));
    float2 uLocation1  = float2(*(faceBuf+2), *(faceBuf+3));
    float2 uLocation2  = float2(*(faceBuf+4), *(faceBuf+5));
    
    float2 vTexCoord = float2(float(gid.x) / float(inTexture.get_width()), float(gid.y)/float(inTexture.get_height()));
    float4 outColor  = inTexture.read(gid_new);
    
    if (0)//(uLocation2.x>0.03) && (uLocation2.y > 0.03))
    {
        float2 resultCoord = vTexCoord;
        
        float2 x_y_proportion = float2(0.5625, 1.0);
        float2 curCoord = vTexCoord * x_y_proportion;
        float weight = 1.0;
        
        //enlarge eyes
        float eyeRadius = 0.4638;
        
        float aspect = 1.0;
        float toLeftEyeCenterDistance =  distance(float2(aspect*curCoord.x, curCoord.y), float2(aspect*uLocation0.x, uLocation0.y));
        if (toLeftEyeCenterDistance <= eyeRadius)
        {
            weight = toLeftEyeCenterDistance / eyeRadius;
            weight = pow(weight, 0.15);
            weight = clamp(weight, 0.001, 1.0);
            weight = (weight - 1.0)*uBigeyeIntensity +1.0;
            curCoord = uLocation0 + (curCoord - uLocation0) * weight;
            
        }
        
        float toRightEyeCenterDistance = distance(float2(aspect*curCoord.x, curCoord.y), float2(aspect*p_eyecenterright.x, p_eyecenterright.y));
        if (toRightEyeCenterDistance <= eyeRadius)
        {
            weight = toRightEyeCenterDistance / eyeRadius;
            weight = pow(weight, 0.15);
            weight = clamp(weight, 0.001, 1.0);
            weight = (weight - 1.0)*uBigeyeIntensity +1.0;
            curCoord = p_eyecenterright + (curCoord - p_eyecenterright) * weight;
        }
        
        resultCoord = curCoord / x_y_proportion;
        
        gid_new = uint2(uint(resultCoord.x * inTexture.get_width()), uint(resultCoord.y * inTexture.get_height()) );
        
        outColor  = inTexture.read(gid_new);
        //float4(1.0,0.4,0.8, 0.5);//
        //outColor = float4(uLocation0, uLocation1);
    }
    
    outTexture.write(outColor, gid);
}

