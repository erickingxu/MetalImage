//
//  Crop.metal
//  MetalImage
//
//  Created by erickingxu on 10/4/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInOut
{
    float4 m_Position [[position]];
    float2 m_TexCoord [[user(texturecoord)]];
};

vertex VertexInOut cropVertex(constant float4         *pPosition[[ buffer(0) ]],
                               constant packed_float2  *pTexCoords[[ buffer(1) ]],
                               uint                     vid[[ vertex_id ]]        )
{
    VertexInOut outVertices;
    
    outVertices.m_Position =  pPosition[vid];
    outVertices.m_TexCoord =  pTexCoords[vid];
    
    return outVertices;
}

fragment half4 cropFragment(VertexInOut inFrag[[ stage_in ]], texture2d<half> inTex[[ texture(0) ]], texture2d<half> outTex[[texture(1)]])
{
    constexpr sampler qsampler;
    half4 srcColor    = inTex.sample(qsampler, inFrag.m_TexCoord);
    
    half4 outColor = srcColor;
   
    return outColor;
}

