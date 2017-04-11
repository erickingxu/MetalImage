//
//  MetalImageObjLoader.m
//  MetalImage
//
//  Created by erickingxu on 15/1/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//
#include "shaderTypes.h"
#import "MetalImageObjLoader.h"
#import <ModelIO/ModelIO.h>

@implementation mtkEssentialsSubmesh {
    /*
     Using ivars instead of properties to avoid any performance penalities with
     the Objective-C runtime.
     */
    id<MTLBuffer> _materialUniforms;
    id<MTLTexture> _diffuseTexture;
    MTKSubmesh *_submesh;
}

- (instancetype)initWithSubmesh:(MTKSubmesh *)mtkSubmesh mdlSubmesh:(MDLSubmesh*)mdlSubmesh device:(id<MTLDevice>)device {
    self = [super init];
    
    if (self) {
        _materialUniforms = [device newBufferWithLength:sizeof(MaterialUniforms) options:0];
        
        MaterialUniforms *materialUniforms = (MaterialUniforms *)[_materialUniforms contents];
        
        _submesh = mtkSubmesh;
        
        // Iterate through the Material's properties...
        
        for (MDLMaterialProperty *property in mdlSubmesh.material) {
            if ([property.name isEqualToString:@"baseColorMap"]) {
                if (property.type == MDLMaterialPropertyTypeString) {
                    NSMutableString *URLString = [[NSMutableString alloc] initWithString:@"file://"];
                    [URLString appendString:property.stringValue];
                    
                    NSURL *textureURL = [NSURL URLWithString:URLString];
                    
                    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
                    
                    NSError *error;
                    _diffuseTexture = [textureLoader newTextureWithContentsOfURL:textureURL options:nil error:&error];
                    
                    if (!_diffuseTexture) {
                        [NSException raise:@"diffuse texture load" format:@"%@", error.localizedDescription];
                    }
                }
            }
            else if ([property.name isEqualToString:@"specularColor"]) {
                if (property.type == MDLMaterialPropertyTypeFloat4) {
                    materialUniforms->specularColor = property.float4Value;
                }
                else if (property.type == MDLMaterialPropertyTypeFloat3) {
                    materialUniforms->specularColor.xyz = property.float3Value;
                    materialUniforms->specularColor.w = 1.0;
                }
            }
            else if ([property.name isEqualToString:@"emission"]) {
                if(property.type == MDLMaterialPropertyTypeFloat4) {
                    materialUniforms->emissiveColor = property.float4Value;
                }
                else if (property.type == MDLMaterialPropertyTypeFloat3) {
                    materialUniforms->emissiveColor.xyz = property.float3Value;
                    materialUniforms->emissiveColor.w = 1.0;
                }
            }
        }
    }
    return self;
}

- (void) renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder {
    // Set material values and textures.
    
    if(_diffuseTexture) {
        [encoder setFragmentTexture:_diffuseTexture atIndex:DiffuseTextureIndex];
    }
    
    [encoder setFragmentBuffer:_materialUniforms offset:0 atIndex:MaterialUniformBuffer];
    [encoder setVertexBuffer:_materialUniforms offset:0 atIndex:MaterialUniformBuffer];
    
    // Draw the submesh.
    [encoder drawIndexedPrimitives:_submesh.primitiveType indexCount:_submesh.indexCount indexType:_submesh.indexType indexBuffer:_submesh.indexBuffer.buffer indexBufferOffset:_submesh.indexBuffer.offset];
}

@end

@implementation mtkEssentialsMesh {
    /*
     Using ivars instead of properties to avoid any performance penalities with
     the Objective-C runtime.
     */
    
    MTKMesh *_mesh;
    NSMutableArray<mtkEssentialsSubmesh *> *_submeshes;
}

- (instancetype)initWithMesh:(MTKMesh *)mtkMesh mdlMesh:(MDLMesh*)mdlMesh device:(id<MTLDevice>)device {
    self = [super init];
    
    if (self) {
        _mesh = mtkMesh;
        
        // Create an array to hold this mesh's submeshes.
        _submeshes = [[NSMutableArray alloc] initWithCapacity:mtkMesh.submeshes.count];
        
        assert(mtkMesh.submeshes.count == mdlMesh.submeshes.count);
        
        for(NSUInteger index = 0; index < mtkMesh.submeshes.count; index++) {
            // Create our own app specifc submesh to hold the MetalKit submesh.
            mtkEssentialsSubmesh *submesh =
            [[mtkEssentialsSubmesh alloc] initWithSubmesh:mtkMesh.submeshes[index]
                                                        mdlSubmesh:mdlMesh.submeshes[index]
                                                            device:device];
            
            [_submeshes addObject:submesh];
        }
        
    }
    
    return self;
}

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder {
    NSUInteger bufferIndex = 0;
    
    for (MTKMeshBuffer *vertexBuffer in _mesh.vertexBuffers) {
        // Set mesh's vertex buffers.
        if(vertexBuffer.buffer != nil) {
            [encoder setVertexBuffer:vertexBuffer.buffer offset:vertexBuffer.offset atIndex:bufferIndex];
        }
        
        bufferIndex++;
    }
    
    for(mtkEssentialsSubmesh *submesh in _submeshes) {
        // Render each submesh.
        [submesh renderWithEncoder:encoder];
    }
}
@end


@implementation MetalImageObjLoader


-(BOOL)initWithVertexDesc:(MDLVertexDescriptor*)modelVertexDescriptor inDevice:(id<MTLDevice>)device fromResource:(NSURL*)mtlRespath
{
    if (!modelVertexDescriptor || !mtlRespath || !device)
    {
        return NO;
    }
    MTKMeshBufferAllocator *bufferAllocator = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
    /*
     Load Model I/O Asset with mdlVertexDescriptor, specifying vertex layout and
     bufferAllocator enabling ModelIO to load vertex and index buffers directory
     into Metal GPU memory.
     */
    MDLAsset *asset = [[MDLAsset alloc] initWithURL:mtlRespath vertexDescriptor:modelVertexDescriptor bufferAllocator:bufferAllocator];
    
    // Create MetalKit meshes.
    NSArray<MTKMesh *> *mtkMeshes;
    NSArray<MDLMesh *> *mdlMeshes;
    NSError *error;
    mtkMeshes = [MTKMesh newMeshesFromAsset:asset
                                     device:device
                               sourceMeshes:&mdlMeshes
                                      error:&error];
    
    if (!mtkMeshes) {
        NSLog(@"Failed to create mesh, error %@", error);
        return NO;
    }
    
    
    // Create our array of App-Specific mesh wrapper objects.
    _meshes = [[NSMutableArray alloc] initWithCapacity:mtkMeshes.count];
    
    
    assert(mtkMeshes.count == mdlMeshes.count);
    
    for (NSUInteger index = 0; index < mtkMeshes.count; index++) {
        mtkEssentialsMesh *mesh = [[mtkEssentialsMesh alloc]initWithMesh:mtkMeshes[index]
                                                                                   mdlMesh:mdlMeshes[index]
                                                                                    device:device];
        [_meshes addObject:mesh];
    }
    return YES;
}

@end
