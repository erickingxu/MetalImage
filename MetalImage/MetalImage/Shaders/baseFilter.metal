//
//  baseFilter.metal
//  MetalImage
//
//  Created by erickingxu on 9/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void basePass(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                      texture2d<half, access::write> outTexture  [[ texture(1) ]],
                      uint2                          gid         [[ thread_position_in_grid ]])
{
    half4 inColor  = inTexture.read(gid);
    outTexture.write(inColor, gid);
}

