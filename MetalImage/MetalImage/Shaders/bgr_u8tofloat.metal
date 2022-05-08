//
//  u8tofloat.metal
//  MetalImage
//
//  Created by xuqing on 2022/1/26.
//  Copyright © 2022 erickingxu. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void rgb2bgr_float(texture2d<half, access::read>   inTex[[texture(0)]],
                         texture2d<half, access::write>  outTex[[texture(1)]],
                         uint2                            gid[[thread_position_in_grid]])
{
    if (gid.x >= outTex.get_width() || gid.y >= outTex.get_height()) {
        return;
    }
    half4 res = inTex.read(gid);
    outTex.write(res.xxxx, gid);
}
