//
//  SumReduce.metal
//  MetalVideoFilter
//
//  Created by xuqing on 6/2/2017.
//  Copyright © 2017 xuqing. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

/* halved number of blocks */
#define THREADGROUP_SIZE  16

kernel void sumReduceOptimize_X(texture2d<float, access::read> inTexture[[texture(0)]],
                              volatile device atomic_uint *resultY [[ buffer(0) ]],
                              uint2 id [[ thread_position_in_grid ]],
                              uint tid [[ thread_index_in_threadgroup ]],
                              uint2 bid [[ threadgroup_position_in_grid ]],
                              uint2 blockDim [[ threads_per_threadgroup ]])
{
    uint h = (uint)inTexture.get_height();
    
    threadgroup uint shared_memory[THREADGROUP_SIZE*THREADGROUP_SIZE];
    threadgroup uint shared_memory_Y[4*THREADGROUP_SIZE];
    
    for(uint j =0; j < h; j += bid.y*(blockDim.y*2) )
    {
        uint i = bid.x * (blockDim.x * 2) + tid;//block index * blocksize+thread index
        uint k = bid.y * (blockDim.y * 2) + tid;
        uint2 pos0  = uint2(i,k), pos1 = uint2(i+blockDim.x, k+blockDim.y);
        
        shared_memory[tid] = (uint)(255*(inTexture.read(pos0).x + inTexture.read(pos1).x));
        threadgroup_barrier(mem_flags::mem_none);
        // reduction in shared memory
        for (uint s = blockDim.x / 2; s > 0; s >>= 1)
        {
            if (tid < s) {
                shared_memory[tid] += shared_memory[tid + s];
            }
            threadgroup_barrier(mem_flags::mem_none);
        }
        
        // it's not recommended (just to show atomic operation capability)!
        if (0 == tid)
        {
            shared_memory_Y[j] = shared_memory[0];
            threadgroup_barrier(mem_flags::mem_none);
        }
    }
    ///////////////////////////////////////////////
    // reduction in shared memory
    for (uint s = blockDim.x / 2; s > 0; s >>= 1)
    {
        if (tid < s) {
            shared_memory_Y[tid] += shared_memory_Y[tid + s];
        }
        threadgroup_barrier(mem_flags::mem_none);
    }
    
    // it's not recommended (just to show atomic operation capability)!
    if (0 == tid)
    {
        atomic_fetch_add_explicit(resultY, shared_memory_Y[0], memory_order_relaxed);
    }
}

kernel void sumReduceOptimize_Y(const device uint *array [[ buffer(0) ]],
                           volatile device atomic_uint *result [[ buffer(1) ]],
                           uint id [[ thread_position_in_grid ]],
                           uint tid [[ thread_index_in_threadgroup ]],
                           uint bid [[ threadgroup_position_in_grid ]],
                           uint blockDim [[ threads_per_threadgroup ]]) {
    
    threadgroup uint shared_memory[THREADGROUP_SIZE];
    
    uint i = bid * (blockDim * 2) + tid;
    
    shared_memory[tid] = array[i] + array[i + blockDim];
    
    threadgroup_barrier(mem_flags::mem_none);
    
    // reduction in shared memory
    for (uint s = blockDim / 2; s > 0; s >>= 1)
    {
        if (tid < s) {
            shared_memory[tid] += shared_memory[tid + s];
        }
        threadgroup_barrier(mem_flags::mem_none);
    }
    
    // it's not recommended (just to show atomic operation capability)!
    if (0 == tid)
    {
        atomic_fetch_add_explicit(result, shared_memory[0], memory_order_relaxed);
    }
}

