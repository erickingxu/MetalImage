//
//  MetalImageTexture.m
//  MetalImage
//
//  Created by xuqing on 8/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "MetalImageTexture.h"
#import <UIKit/UIKit.h>

@implementation MetalImageTexture
-(id)initWithResource:(NSString*)fileStr ;
{
    //nameStr must be bundle path
    if (!fileStr  ||  !(self = [super init]))
    {
        return nil;
    }
    
    _filePathStr = fileStr;
        
    _width = _height = 0;
    _depth = 1;
    _pixelFormat = MTLPixelFormatBGRA8Unorm;
    _target   = MTLTextureType2D;
	_texture   = nil;
    _flip = YES;
    return self;
}

-(id)initWithWidth:(uint32_t)imgWidth withHeight:(uint32_t)imgHeight;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _filePathStr = nil;
    
    _width = imgWidth;
    _height = imgHeight;
    _depth = 1;
    _pixelFormat = MTLPixelFormatBGRA8Unorm;
    _target   = MTLTextureType2D;
    
    _texture   = nil;
    _flip = NO;
    return self;
}

- (void) dealloc
{
    _filePathStr    = nil;
    _texture = nil;
} // dealloc

- (void) setFlip:(BOOL)flip
{
    _flip = flip;
} // setFlip

-(id)initWithImage:(CGImageRef)img andWithMetalDevice:(id <MTLDevice>)device;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    if (!img)
    {
        return nil;
    }

    _depth = 1;
    _pixelFormat = MTLPixelFormatBGRA8Unorm;
    _target   = MTLTextureType2D;
    
    _texture   = nil;
    _flip = YES;

    self.img    = [UIImage imageWithCGImage:img];
    self.width  = (uint32_t) CGImageGetWidth(img);
    self.height = (uint32_t) CGImageGetHeight(img);
    uint32_t rowBytes = self.width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef    imgContex  = CGBitmapContextCreate(NULL, self.width, self.height, 8, rowBytes, colorSpace,  kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colorSpace);
    
    if(!imgContex)
    {
        return nil;
    }
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, self.width, self.height);
    
    CGContextClearRect(imgContex, bounds);
    
    // Vertical Reflect
    if(self.flip)
    {
        CGContextTranslateCTM(imgContex, self.width, self.height);
        CGContextScaleCTM(imgContex, -1.0, -1.0);
    } // if
    CGContextDrawImage(imgContex, bounds, img);
    
    MTLTextureDescriptor *txtDescrp = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.pixelFormat width:self.width height: self.height mipmapped:NO];
    
    self.target  = txtDescrp.textureType;//similar to Texture_2D
    self.texture = [device newTextureWithDescriptor:txtDescrp];//load txture into device for fbo
    if (!self.texture)
    {
        CGContextRelease(imgContex);
        return nil;
    }
    
    const void *pPixels = CGBitmapContextGetData(imgContex);
    
    if(pPixels != NULL)
    {
        MTLRegion region = MTLRegionMake2D(0, 0, self.width, self.height);
        
        [_texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:pPixels
                    bytesPerRow:rowBytes];
    }
    
    CGContextRelease(imgContex);

    return self;
}

-(BOOL)loadTextureIntoDevice:(id <MTLDevice>)device;
{
    if (! self.filePathStr && self.width > 0 && self.height > 0 )
    {
        MTLTextureDescriptor *txtDescrp = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.pixelFormat width:self.width height: self.height mipmapped:NO];
        
        self.target  = txtDescrp.textureType;//similar to Texture_2D
        self.texture = [device newTextureWithDescriptor:txtDescrp];//load txture into device for fbo
        return YES;
    }
    
    UIImage *img = [UIImage imageWithContentsOfFile:self.filePathStr];
    if (!img)
    {
        return NO;
    }
    
    self.width  = (uint32_t) CGImageGetWidth(img.CGImage);
    self.height = (uint32_t) CGImageGetHeight(img.CGImage);
	uint32_t rowBytes = self.width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef    imgContex  = CGBitmapContextCreate(NULL, self.width, self.height, 8, rowBytes, colorSpace,  kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colorSpace);
    
    if(!imgContex)
    {
        return NO;
    } // if
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, self.width, self.height);
    
    CGContextClearRect(imgContex, bounds);
    
    // Vertical Reflect
    if(self.flip)
    {
        CGContextTranslateCTM(imgContex, self.width, self.height);
        CGContextScaleCTM(imgContex, -1.0, -1.0);
    } // if
    CGContextDrawImage(imgContex, bounds, img.CGImage);
    
    MTLTextureDescriptor *txtDescrp = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.pixelFormat width:self.width height: self.height mipmapped:NO];
    
    self.target  = txtDescrp.textureType;//similar to Texture_2D
    self.texture = [device newTextureWithDescriptor:txtDescrp];//load txture into device for fbo
    if (!self.texture)
    {
	CGContextRelease(imgContex);
        return NO;
    }
    
   // [self.texture replaceRegion:MTLRegionMake2D(0, 0, self.width, self.height) mipmapLevel:0 withBytes:CGBitmapContextGetData(imgContex) bytesPerRow: 4*self.width];
    const void *pPixels = CGBitmapContextGetData(imgContex);
    
    if(pPixels != NULL)
    {
        MTLRegion region = MTLRegionMake2D(0, 0, self.width, self.height);
        
        [_texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:pPixels
                    bytesPerRow:rowBytes];
    } // if
    
    CGContextRelease(imgContex);
    
    return YES;
}


@end
//////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation  MetalImageTextureCube
// assumes png file
- (BOOL)loadTextureIntoDevice:(id <MTLDevice>)device
{
    UIImage *image = [UIImage imageWithContentsOfFile:self.filePathStr];
    if (!image)
        return NO;
    
    self.width = (uint32_t)CGImageGetWidth(image.CGImage);
    self.height = (uint32_t)CGImageGetHeight(image.CGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate( NULL, self.width, self.height, 8, 4 * self.width, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast );
    CGContextDrawImage( context, CGRectMake( 0, 0, self.width, self.height ), image.CGImage );
    
    unsigned Npixels = self.width * self.width;
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm size:self.width mipmapped:NO];
    self.target = texDesc.textureType;
    self.texture = [device newTextureWithDescriptor:texDesc];
    if (!self.texture)
        return NO;
    
    void *imageData = CGBitmapContextGetData(context);
    for (int i = 0; i < 6; i++)
    {
        [self.texture replaceRegion:MTLRegionMake2D(0, 0, self.width, self.width)
                        mipmapLevel:0
                              slice:i
                          withBytes:imageData + (i * Npixels * 4)
                        bytesPerRow:4 * self.width
                      bytesPerImage:Npixels * 4];
    }
    
    CGColorSpaceRelease( colorSpace );
    CGContextRelease(context);
    
    return YES;
}

@end

