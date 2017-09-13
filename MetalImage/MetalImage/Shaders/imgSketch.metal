//
//  imgSketch.metal
//  MetalImage
//
//  Created by xuqing on 13/9/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#define uGaussSize 19 ///could be changed by function value for kernel

constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

kernel void imgSketch(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                      texture2d<half, access::write> outTexture  [[ texture(1) ]],
                      uint2                          gid         [[ thread_position_in_grid ]])
{
    
    half4 inColorA  = inTexture.read(gid);
    half4 invertColorB = half4(1.0) - inColorA;
    half  grayInvert     = dot(inColorA.rgb, kRec709Luma);
    half  gaussC0 = 0.0h;
    half  gaussC1 = 0.0h;
    half  gaussC  = 0.0h;
    
    half4 v0 = half4(1.0) - inTexture.read(gid + uint2(-uGaussSize * 4, 0));
    half  grayv0     = dot(v0.rgb, kRec709Luma);
    half4 v1 = half4(1.0) - inTexture.read(gid + uint2(-uGaussSize * 3, 0));
    half  grayv1     = dot(v1.rgb, kRec709Luma);
    half4 v2 = half4(1.0) - inTexture.read(gid + uint2(-uGaussSize * 2, 0));
    half  grayv2     = dot(v2.rgb, kRec709Luma);
    
    half4 v3 = half4(1.0) - inTexture.read(gid + uint2(-uGaussSize * 1, 0));
    half  grayv3     = dot(v3.rgb, kRec709Luma);
    
    half4 v4 = half4(1.0) - inTexture.read(gid);
    half  grayv4     = dot(v4.rgb, kRec709Luma);
    
    half4 v5 = half4(1.0) - inTexture.read(gid + uint2(uGaussSize * 1, 0));
    half  grayv5     = dot(v5.rgb, kRec709Luma);
    
    half4 v6 = half4(1.0) - inTexture.read(gid + uint2(uGaussSize * 2, 0));
    half  grayv6     = dot(v6.rgb, kRec709Luma);
    
    half4 v7 = half4(1.0) - inTexture.read(gid + uint2(uGaussSize * 3, 0));
    half  grayv7     = dot(v7.rgb, kRec709Luma);
    
    half4 v8 = half4(1.0) - inTexture.read(gid + uint2(uGaussSize * 4, 0));
    half  grayv8     = dot(v8.rgb, kRec709Luma);
    
    gaussC0 = grayv0 * 0.0162162162h + grayv1 * 0.0540540541h + grayv2 * 0.1216216216h + grayv3 * 0.1945945946h + grayv4 * 0.2270270270h + grayv5  * 0.1945945946h + grayv6 * 0.1216216216h + grayv7 * 0.0540540541h + grayv8 * 0.0162162162h;
    
    half4 h0 = half4(1.0) - inTexture.read(gid + uint2(0,-uGaussSize * 4));
    half  grayh0     = dot(h0.rgb, kRec709Luma);
    half4 h1 = half4(1.0) - inTexture.read(gid + uint2(0,-uGaussSize * 3));
    half  grayh1     = dot(h1.rgb, kRec709Luma);
    half4 h2 = half4(1.0) - inTexture.read(gid + uint2(0,-uGaussSize * 2));
    half  grayh2     = dot(h2.rgb, kRec709Luma);
    half4 h3 = half4(1.0) - inTexture.read(gid + uint2(0,-uGaussSize * 1));
    half  grayh3     = dot(h3.rgb, kRec709Luma);
    half4 h4 = half4(1.0) - inTexture.read(gid);
    half  grayh4     = dot(h4.rgb, kRec709Luma);
    half4 h5 = half4(1.0) - inTexture.read(gid + uint2(0,uGaussSize * 1));
    half  grayh5     = dot(h5.rgb, kRec709Luma);
    half4 h6 = half4(1.0) - inTexture.read(gid + uint2(0,uGaussSize * 2));
    half  grayh6     = dot(h6.rgb, kRec709Luma);
    half4 h7 = half4(1.0) - inTexture.read(gid + uint2(0,uGaussSize * 3));
    half  grayh7     = dot(h7.rgb, kRec709Luma);
    half4 h8 = half4(1.0) - inTexture.read(gid + uint2(0,uGaussSize * 4));
    half  grayh8     = dot(h8.rgb, kRec709Luma);
    
    gaussC1 = grayh0 * 0.0162162162h + grayh1 * 0.0540540541h + grayh2 * 0.1216216216h + grayh3 * 0.1945945946h + grayh4 * 0.2270270270h + grayh5  * 0.1945945946h + grayh6 * 0.1216216216h + grayh7 * 0.0540540541h + grayh8 * 0.0162162162h;
    
    gaussC = (gaussC0 + gaussC1) / 2.0h;
    
    half dstColor = fmin( grayInvert + (grayInvert*gaussC) / (1.0h - gaussC), 1.0h);
    
    outTexture.write(half4(dstColor,dstColor,dstColor,1.0), gid);
}

