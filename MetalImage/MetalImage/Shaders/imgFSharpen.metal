//
//  imgFSharpen.metal
//  MetalImage
//
//  Created by xuqing on 8/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void faceSharpen(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                     texture2d<half, access::write> outTexture  [[ texture(1) ]],
                     uint2                          gid         [[ thread_position_in_grid ]])
{
    half4 inColor  = inTexture.read(gid);//half4(0.0, 1.0, 0.0, 1.0);//
    outTexture.write(inColor, gid);
}
