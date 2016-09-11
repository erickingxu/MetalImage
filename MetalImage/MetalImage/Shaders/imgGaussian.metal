//
//  imgGaussian.metal
//  MetalImage
//
//  Created by xuqing on 27/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void gaussian_blur_2d(texture2d<float, access::read>  inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             texture2d<float, access::read>  weights [[texture(2)]],
                             uint2                           gid [[thread_position_in_grid]])
{
    int size = weights.get_width();
    int radius = size / 2;
    
    float4 accumColor(0.0, 0.0, 0.0, 0.0);
    for (int j = 0; j < size; ++j)
    {
        for (int i = 0; i < size; ++i)
        {
            uint2 kernelIndex(i, j);
            uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
            float4 color = inTexture.read(textureIndex).rgba;
            float4 weight = weights.read(kernelIndex).rrrr;
            accumColor += weight * color;
        }
    }
    
    outTexture.write(float4(accumColor.rgb, 1), gid);
}

//////////////////////////Optimize Gaussian algorithm with two pass/////////////////////////
kernel void gaussian_BlurHorizontal(texture2d<float, access::read>  inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             texture1d<float, access::sample> weights [[texture(2)]],
                             uint2                           gid [[thread_position_in_grid]])
{
    int size = weights.get_width()*2 - 1;
    int radius = weights.get_width() - 1;
   
    float4 xColor(0.0, 0.0, 0.0, 0.0);
  
    for (int i = 0; i < size; ++i)
    {
       // uint    widthOffset = radius*2 + 1;
        uint2   textureIndex(gid.x + (i - radius)*radius, gid.y);
        float4  color = inTexture.read(textureIndex).rgba;
        int   xindx = abs(i - radius);
        float  weight = weights.read(xindx).x;
        xColor  += float4(weight)*color;
    }
    //xColor = xColor/(float)size;
    outTexture.write(float4(xColor.rgb, 1), gid);
}

kernel void gaussian_BlurVertical(texture2d<float, access::read>  inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  texture1d<float, access::sample> weights [[texture(2)]],
                                  uint2                           gid [[thread_position_in_grid]])
{
    int size = weights.get_width()*2 - 1;
    int radius = weights.get_width() - 1;
    
    float4 yColor(0.0, 0.0, 0.0, 0.0);
    
    for (int j = 0; j < size; ++j)
    {
      //  uint    heightOffset = radius*2 + 1;
        uint2 textureIndex(gid.x , gid.y + (j - radius)*radius);
        float4 color = inTexture.read(textureIndex).rgba;
        int   yindx = abs(j - radius);
        float weight = weights.read(yindx).x;
        yColor +=  float4(weight)*color;
    }
    //yColor = yColor/(float)size;
    outTexture.write(float4(yColor.rgb, 1), gid);
}

////////////////////////////////////////////////////////////////////////////////////////////
inline float3 kernel_gaussianBlur(  texture2d<float, access::sample> inTexture,
                                    texture2d<float, access::write>  outTexture,
                                    texture1d<float, access::sample> weights,
                                    texture1d<float, access::sample> offsets,                                  
                                    float2 offsetPixel,
                                    uint2 gid)
{
    
    constexpr sampler p(address::clamp_to_edge, filter::linear, coord::pixel);
    
    float2 texCoord  = float2(gid);
    
    float3 color(0);
    
    for( uint i = 0; i < weights.get_width(); i++ )
    {
        float2 texCoordOffset = offsets.read(i).x * offsetPixel;
        float3 pixel          = inTexture.sample(p, texCoord - texCoordOffset ).rgb;
        pixel += inTexture.sample(p, texCoord + texCoordOffset).rgb;
        color += weights.read(i).x * pixel;
    }
    
    return color;
}


kernel void kernel_gaussianBlurHorizontalPass(texture2d<float, access::sample> inTexture         [[texture(0)]],
                                              texture2d<float, access::write>  outTexture        [[texture(1)]],
                                              texture1d<float, access::sample> weights           [[texture(2)]],
                                              texture1d<float, access::sample> offsets           [[texture(3)]],
                                              uint2 gid [[thread_position_in_grid]])
{
    
    float3 color = kernel_gaussianBlur(inTexture,outTexture,weights,offsets,float2(1,0),gid);
    outTexture.write(float4(color,1),gid);
}

kernel void kernel_gaussianBlurVerticalPass(texture2d<float, access::sample> inTexture         [[texture(0)]],
                                            texture2d<float, access::write>  outTexture        [[texture(1)]],
                                            texture1d<float, access::sample> weights           [[texture(2)]],
                                            texture1d<float, access::sample> offsets           [[texture(3)]],
                                            uint2 gid [[thread_position_in_grid]])
{
    
    float3 color = kernel_gaussianBlur(inTexture,outTexture,weights,offsets,float2(0,1),gid);
    outTexture.write(float4(color,1),gid);
}