//
//  imgEyeBig.metal
//  MetalImage
//
//  Created by ericking on 22/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

float2 pointsStretch(float2 textureCoord, float2 originPosition, float2 direction, float radius, float curve)
{
    float infect = distance(textureCoord, originPosition) / radius;
    infect = clamp(1.0 - infect, 0.0, 1.0);
    infect = pow(infect, curve);
    return direction * infect;
}

kernel void eyefSharpen(texture2d<float, access::read>  inTexture   [[ texture(0) ]],
                       texture2d<float, access::write> outTexture  [[ texture(1) ]],
                       constant float*                 faceBuf     [[buffer(0)]],
                       uint2                           gid         [[ thread_position_in_grid ]])

{
    float             eStreth = 1.0;
    
    uint2 gid_new(gid.x, gid.y);
    ///get data from faceBuf into loc
    float2 eLpt  = float2(*faceBuf, *(faceBuf+1));
    float2 eRpt  = float2(*(faceBuf+2), *(faceBuf+3));
    float2 fCntPt  = float2(*(faceBuf+4), *(faceBuf+5));
    
    float2 vTexCoord = float2(float(gid.x) / float(inTexture.get_width()), float(gid.y)/float(inTexture.get_height()));
    float4 outColor  = inTexture.read(gid_new);
    
    if ((fCntPt.x>0.03) && (fCntPt.y > 0.03))
    {
        float2 resultCoord = vTexCoord;
        
        float2 wh_scale = float2(0.5625, 1.0);
        float2 curCoord = vTexCoord * wh_scale;
        float weight = 1.0;
        
        //enlarge eyes
        float eyeRadius = 0.4638;
        
        float aspect = 1.0;
        float dist2eLpt =  distance(float2(aspect*curCoord.x, curCoord.y), float2(aspect*eLpt.x, eLpt.y));
        if (dist2eLpt <= eyeRadius)
        {
            weight = dist2eLpt / eyeRadius;
            weight = pow(weight, 0.15);
            weight = clamp(weight, 0.001, 1.0);
            weight = (weight - 1.0)*eStreth +1.0;
            curCoord = eLpt + (curCoord - eLpt) * weight;
            
        }
        
        float dist2eRpt = distance(float2(aspect*curCoord.x, curCoord.y), float2(aspect*eRpt.x, eRpt.y));
        if (dist2eRpt <= eyeRadius)
        {
            weight = dist2eRpt / eyeRadius;
            weight = pow(weight, 0.2);
            weight = clamp(weight, 0.0013, 1.0);
            weight = (weight - 1.0)*eStreth +1.0;
            curCoord = eRpt + (curCoord - eRpt) * weight;
        }
        
        resultCoord = curCoord / wh_scale;
        
        gid_new = uint2(uint(resultCoord.x * inTexture.get_width()), uint(resultCoord.y * inTexture.get_height()) );
        
        outColor  = inTexture.read(gid_new);
        //float4(1.0,0.4,0.8, 0.5);//
        //outColor = float4(eLpt, eRpt);
    }
    
    outTexture.write(outColor, gid);
}

