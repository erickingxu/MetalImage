//
//  MetalImageTexture.h
//  MetalImage
//
//  Created by erickingxu on 8/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
@interface MetalImageTexture : NSObject

@property(readwrite) id<MTLTexture>  texture;
@property(readwrite) uint32_t        width;
@property(readwrite) uint32_t        height;
@property(readwrite) uint32_t        depth;
@property(readwrite) MTLTextureType        target;
@property(readwrite) uint32_t        pixelFormat;
@property(readwrite) BOOL            hasAlpha;
@property(readwrite) NSString*       filePathStr;
@property(readwrite) BOOL            flip;
@property(readwrite)  UIImage*        img;

-(id)initWithResource:(NSString*)fileStr;
-(id)initWithImage:(CGImageRef)img andWithMetalDevice:(id <MTLDevice>)device;
-(id)initWithWidth:(uint32_t)imgWidth withHeight:(uint32_t)imgHeight;
-(BOOL)loadTextureIntoDevice:(id <MTLDevice>)device;
@end
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
@interface MetalImageTextureCube : MetalImageTexture

@end
