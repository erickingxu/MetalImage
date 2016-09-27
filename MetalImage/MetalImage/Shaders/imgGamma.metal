//
//  imgGamma.metal
//  MetalImage
//
//  Created by xuqing on 17/8/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

//#include <metal_stdlib>
//using namespace metal;
//kernel void Gamma(texture2d<float, access::read> inTexture [[texture(0)]],
//                  texture2d<float, access::write> outTexture [[texture(1)]],
//                  device float *gamma [[buffer(0)]],
//                  uint2 gid [[thread_position_in_grid]])
//{
//    const float4 inColor = inTexture.read(gid);
//    const float4 outColor = float4(pow(inColor.rgb,float3(*gamma)),inColor.a);
//    outTexture.write(outColor, gid);
//}


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
//, device const float *gamma [[buffer(0)]]
fragment half4 gammaFragment(VertexInOut inFrag[[ stage_in ]], texture2d<half> tex2D[[ texture(0) ]])
{
    constexpr sampler qsampler;
    half4 color = tex2D.sample(qsampler, inFrag.m_TexCoord);//half4(r, 0.0, 0.0, 1.0);
    
    return pow(color,2.0);
}


