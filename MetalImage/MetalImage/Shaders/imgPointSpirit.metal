//
//  imgPointSpirit.metal
//  MetalImage
//
//  Created by ericking on 16/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInOut
{
    float4 m_Position [[position]];
    float point_size [[point_size]];
};

vertex VertexInOut pointSpiritVertex(device float4  *pPosition[[ buffer(0) ]],
                                     uint            vid[[ vertex_id ]]       )
{
    VertexInOut outVertices;
    
    outVertices.m_Position = pPosition[vid]; //float4(-0.1, 0.9, 0, 1.0);//
    outVertices.point_size = 25;
    
    return outVertices;
}

fragment half4 pointSpiritFragment(VertexInOut inFrag[[ stage_in ]])
{
    half4 outColor = half4(0.7, 0.2, 0.3, 1.0);
    return outColor;
}

fragment half4 roundSpiritFragment(VertexInOut inFrag[[ stage_in ]], float2 ptCoord [[point_coord]])
{
    ///slow one with discard_fragment method and had a hard edge
//    if(length(ptCoord - float2(0.5)) > 0.5) //inFrag.m_Position.xy
//    {
//        discard_fragment();
//    }
    float dist = length(ptCoord - float2(0.5));
    
    half4 outColor = half4(0.1, 0.9, 0.1, 1.0);
    
    outColor.a = 1.0 - smoothstep(0.4, 0.5, dist);//soft edge
    
    return outColor;
}
