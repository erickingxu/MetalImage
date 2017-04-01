//
//  shaderTypes.h
//  MetalImage
//
//  Created by xuqing on 15/1/2017.
//  Copyright © 2017 xuqing. All rights reserved.
//
//
#ifndef __SHADER_TYPES_H__
#define __SHADER_TYPES_H__

#import <simd/simd.h>

using namespace simd;

/// Indices of vertex attribute in descriptor.
enum VertexAttributes {
    VertexAttributePosition = 0,
    VertexAttributeNormal   = 1,
    VertexAttributeTexcoord = 2,
};

/// Indices for texture bind points.
enum TextureIndex {
    DiffuseTextureIndex = 0
};

/// Indices for buffer bind points.
enum BufferIndex  {
    MeshVertexBuffer      = 0,
    FrameUniformBuffer    = 1,
    MaterialUniformBuffer = 2,
};

/// Per frame uniforms.
struct FrameUniforms
{
    float4x4 model;
    float4x4 view;
    float4x4 projection;
    float4x4 projectionView;
    float4x4 normal;
};

/// Material uniforms.
struct MaterialUniforms {
    float4 emissiveColor;
    float4 diffuseColor;
    float4 specularColor;
    
    float specularIntensity;
    float pad1;
    float pad2;
    float pad3;
};

#endif /* shaderTypes_h */
