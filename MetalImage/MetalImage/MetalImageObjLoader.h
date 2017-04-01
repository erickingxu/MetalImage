//
//  MetalImageObjLoader.h
//  MetalImage
//
//  Created by xuqing on 15/1/2017.
//  Copyright © 2017 xuqing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface mtkEssentialsSubmesh : NSObject

- (instancetype)initWithSubmesh:(MTKSubmesh *)mtkSubmesh mdlSubmesh:(MDLSubmesh*)mdlSubmesh device:(id<MTLDevice>)device;

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder;

@end

@interface mtkEssentialsMesh : NSObject

- (instancetype)initWithMesh:(MTKMesh *)mtkMesh mdlMesh:(MDLMesh*)mdlMesh device:(id<MTLDevice>)device;

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder;

@end


@interface MetalImageObjLoader : NSObject
{
        NSMutableArray<mtkEssentialsMesh *> *_meshes;
}
@end
