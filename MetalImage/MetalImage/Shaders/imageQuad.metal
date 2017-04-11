//
//  File.metal
//  MetalImage
//
//  Created by erickingxu on 8/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//
#include <metal_stdlib>

using namespace metal;


struct VertexInOut
{
    float4 m_Position [[position]];
    float2 m_TexCoord [[user(texturecoord)]];
};

vertex VertexInOut imageQuadVertex(constant float4         *pPosition[[ buffer(0) ]],
                                      constant packed_float2  *pTexCoords[[ buffer(1) ]],
                                      uint                     vid[[ vertex_id ]]        )
{
    VertexInOut outVertices;
    
    outVertices.m_Position =  pPosition[vid];
    outVertices.m_TexCoord =  pTexCoords[vid];
    
    return outVertices;
}

fragment half4 imageQuadFragment(VertexInOut inFrag[[ stage_in ]], texture2d<half> tex2D[[ texture(0) ]])
{
    constexpr sampler qsampler;
    //float r = inFrag.m_TexCoord.x;
    //float g = inFrag.m_TexCoord.y;
    half4 color = tex2D.sample(qsampler, inFrag.m_TexCoord);//half4(r, 0.0, 0.0, 1.0);
    
    return color;
}


//No need flip color for mxnet data and model
kernel void adjust_mean_rgb(texture2d<half, access::read> inTexture [[texture(0)]],
                            texture2d<half, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]])
{
    half4 inColor = inTexture.read(gid);
    half4 outColor = half4(inColor.x*255.0 - 123.68, inColor.y*255.0 - 116.779, inColor.z*255.0 - 103.939, 1.0);
    outTexture.write(outColor, gid);
}

kernel void reverse_mean_rgb_mxnet(texture2d<half, access::read> inTexture[[texture(0)]],
                                   texture2d<half, access::write> outTexture[[texture(1)]],
                                   uint2 gid[[thread_position_in_grid]])
{
    half4 inColor = inTexture.read(gid);
    half4 outColor =  half4((inColor.x + 123.68)/255.0, (inColor.y + 116.779)/255.0, (inColor.z+103.939)/255.0, 1.0);
    outTexture.write(outColor, gid);
}

///$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
kernel void nearest_upsample_rgb(texture2d_array<half, access::read> inTexture[[texture(0)]],
                                 texture2d_array<half, access::write> outTexture[[texture(1)]],
                                 uint3 gid[[thread_position_in_grid]])
{
    uint2 p;
    p = uint2(gid.x / 2, gid.y / 2);
    const half4 color = inTexture.read(p, gid.z);
    
    outTexture.write(color, gid.xy, gid.z);
}
///@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


