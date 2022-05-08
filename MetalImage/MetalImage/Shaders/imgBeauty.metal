//
//  Beauty.metal
//  MetalImage
//
//  Created by erickingxu on 23/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
kernel void gaussian_HighPassHorizontal(texture2d<float, access::read>  inTexture [[texture(0)]],
                                        texture2d<float, access::write> outTexture [[texture(1)]],
                                        texture1d<float, access::sample> weights [[texture(2)]],
                                        uint2                           gid [[thread_position_in_grid]])
{
    int size = weights.get_width()*2 - 1;
    int radius = weights.get_width() - 1;
    
    float4 xColor(0.0, 0.0, 0.0, 0.0);
    
    for (int i = 0; i < size; ++i)
    {
        uint2   textureIndex(gid.x + (i - radius)*radius, gid.y);
        float4  color = inTexture.read(textureIndex).rgba;
        int   xindx = abs(i - radius);
        float  weight = 0.5;//weights.read(xindx).x;
        xColor  += float4(weight)*color;
    }
    outTexture.write(float4(xColor.rgb, 1), gid);
}

kernel void gaussian_HighPassVertical(texture2d<float, access::read>  inTexture [[texture(0)]],
                                      texture2d<float, access::read>  srcTexture [[texture(1)]],
                                      texture2d<float, access::write> outTexture [[texture(2)]],
                                      texture1d<float, access::sample> weights [[texture(3)]],
                                      uint2                           gid [[thread_position_in_grid]])
{
    int size = weights.get_width()*2 - 1;
    int radius = weights.get_width() - 1;
    
    float4 yColor(0.0, 0.0, 0.0, 0.0);
    
    for (int j = 0; j < size; ++j)
    {
        uint2 textureIndex(gid.x , gid.y + (j - radius)*radius);
        float4 color = inTexture.read(textureIndex).rgba;
        int   yindx = abs(j - radius);
        float weight = weights.read(yindx).x;
        yColor +=  float4(weight)*color;
    }

    float4 srcColor = srcTexture.read(gid);
    float4 yres = srcColor - yColor + 0.5;
    
    outTexture.write(float4(yres.rgb, yColor.g), gid);
}

kernel void blur_HighPassHorizontal(texture2d<float, access::read>  inTexture [[texture(0)]],
                                    texture2d<float, access::write> outTexture [[texture(1)]],
                                    uint2                           gid [[thread_position_in_grid]])
{
    float4 highpass(0.0, 0.0, 0.0, 0.0);
    
    for (int i = 0; i < 11; ++i)
    {
        uint2 textureIndex(gid.x+ (i - 5) , gid.y );
        float4 color = inTexture.read(textureIndex).rgba;
        highpass +=  color;
    }
    highpass = highpass /11.0;
    outTexture.write(highpass, gid);
}


kernel void beautyPass(
                       texture2d<float, access::read>  highPassTexture [[texture(0)]],
                       texture2d<float, access::read>  srcTexture [[texture(1)]],
                       texture2d<float, access::write> outTexture [[texture(2)]],
                       uint2 gid [[thread_position_in_grid]])
{
    
    float4 highpass(0.0, 0.0, 0.0, 0.0);
    for (int j = 0; j < 11; ++j)
    {
        uint2 textureIndex(gid.x , gid.y + (j - 5));
        float4 color = highPassTexture.read(textureIndex).rgba;
        highpass +=  color;
    }
    highpass = highpass/ 11.0;
    float4 srcColor = srcTexture.read(gid);
    
    float G =  srcColor.g;
    float G1 = 1.0 -  highpass.g;
    G1 = (min(1.0, max(0.0, ((G)+2.0*(G1)-1.0))));
    float G2 = mix(G, G1, 0.5);//softlight
    G2 = ((G2) <= 0.5 ? (pow(G2, 2.0) * 2.0) : (1.0 - pow((1.0 - G2), 2.0) * 2.0) );
    float4 res = mix( srcColor, highpass.aaaa, G2);//hardlight
    
    outTexture.write(float4(mix(srcColor.rgb, res.rgb, 0.52), 1.0), gid);
}



