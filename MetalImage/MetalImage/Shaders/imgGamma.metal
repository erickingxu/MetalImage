//
//  imgGamma.metal
//  MetalImage
//
//  Created by erickingxu on 17/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.


#include <metal_graphics>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_texture>

using namespace metal;

struct VertexInOut
{
    float4 m_Position [[position]];
    float2 m_TexCoord [[user(texturecoord)]];
};

vertex VertexInOut gammaVertex(constant float4         *pPosition[[ buffer(0) ]],
                                   constant packed_float2  *pTexCoords[[ buffer(1) ]],
                                   uint                     vid[[ vertex_id ]]        )
{
    VertexInOut outVertices;
    
    outVertices.m_Position =  pPosition[vid];
    outVertices.m_TexCoord =  pTexCoords[vid];
    
    return outVertices;
}

fragment half4 gammaFragment(VertexInOut inFrag[[ stage_in ]], texture2d<half> texGamma[[ texture(0) ]],  constant float* unfm_gamma[[buffer(0)]])
{
    constexpr sampler qsampler;
    half4 srcColor    = texGamma.sample(qsampler, inFrag.m_TexCoord);
    
    half4 outColor = pow(srcColor,*unfm_gamma);
    return outColor;
}


