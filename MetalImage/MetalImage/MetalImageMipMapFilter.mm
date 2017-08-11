//
//  MetalImageMipMapFilter.m
//  MetalImage
//
//  Created by erickingxu on 27/7/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#import "MetalImageMipMapFilter.h"

@implementation MetalImageMipMapFilter
{
@private
    MTLTextureDescriptor *_textureDescriptor;
    // heaps / fence
    id<MTLHeap> _heap;
    id<MTLFence> _fence;
}


-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.vertexFuncNameStr  =  @"";
    peline.fragmentFuncNameStr=  @"";
    peline.computeFuncNameStr =  @"";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    
    
    if (!self.filterDevice )
    {
        return nil;
        
    }
    
    return self;
}


- (MTLSizeAndAlign) heapSizeAndAlignWithInputTextureDescriptor:(nonnull MTLTextureDescriptor *)inDescriptor
{
    _textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:inDescriptor.pixelFormat
                                                                            width:inDescriptor.width
                                                                           height:inDescriptor.height
                                                                        mipmapped:YES];
    
    // Heap resources must share the same storage mode as the heap.
    _textureDescriptor.storageMode = MTLStorageModePrivate;
    
    return [self.filterDevice heapTextureSizeAndAlignWithDescriptor:_textureDescriptor];
}

-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    
    if (commandBuffer)
    {
        id <MTLTexture> mipMapTexture = [self executeWithCommandBuffer:commandBuffer inputTexture:firstInputTexture.texture heap:_heap fence:_fence];
        if(mipMapTexture)
        {
            outputTexture.texture = mipMapTexture;
       }
    }
    //end if
}

- (_Nullable id <MTLTexture>) executeWithCommandBuffer:(_Nonnull id <MTLCommandBuffer>)commandBuffer
                                          inputTexture:(_Nonnull id <MTLTexture>)inTexture
                                                  heap:(_Nonnull id <MTLHeap>)heap
                                                 fence:(_Nonnull id <MTLFence>)fence
{
    id <MTLTexture> outTexture = [heap newTextureWithDescriptor:_textureDescriptor];
    assert(outTexture && "Failed to allocate on heap, did not request enough resources");
    
    id <MTLBlitCommandEncoder> blitCommandEncoder = [commandBuffer blitCommandEncoder];
    
    if(blitCommandEncoder)
    {
        [blitCommandEncoder waitForFence:fence];
        
        [blitCommandEncoder copyFromTexture:inTexture
                                sourceSlice:0
                                sourceLevel:0
                               sourceOrigin:(MTLOrigin){ 0, 0, 0 }
                                 sourceSize:(MTLSize){ inTexture.width, inTexture.height, inTexture.depth }
                                  toTexture:outTexture
                           destinationSlice:0
                           destinationLevel:0
                          destinationOrigin:(MTLOrigin){ 0, 0, 0}];
        
        [blitCommandEncoder generateMipmapsForTexture:outTexture];
        
        
        
        [blitCommandEncoder updateFence:fence];
        
        [blitCommandEncoder endEncoding];
    }
    
    return outTexture;
}

@end
