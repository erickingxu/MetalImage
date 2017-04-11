//
//  MetalImageCustomView.m
//  MetalImage
//
//  Created by erickingxu on 12/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageCustomView.h"
#import "MetalImageCmdQueue.h"

@implementation MetalImageCustomView
{
    @private
    __weak  CAMetalLayer            *_metalLayer;
    BOOL                            _layerSizeDidUpdate;
    
    id <MTLTexture>                 _depthTexture;
    id <MTLTexture>                 _stencilTexture;
    id <MTLTexture>                 _msaaTexture;
    
}

@synthesize currentDrawable         = _currentDrawable;
@synthesize renderPassDescriptor    = _renderPassDescriptor;
@synthesize filterDelegate          = _filterDelegate;
/////////////////////////////////////////////////////////////////////////
+(Class)layerClass
{
    return [CAMetalLayer class];
}

-(id)initWithFrame:(CGRect)frame
{
    self =  [super initWithFrame:frame];
    if (self )
    {
        [self initCommon];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self  = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initCommon];
    }
    return self;
}

- (MTLRenderPassDescriptor *)renderPassDescriptor
{
    id <CAMetalDrawable> drawable = self.currentDrawable;
    if(!drawable)
    {
        NSLog(@">> ERROR: Failed to get a drawable!");
        _renderPassDescriptor = nil;
    }
    else
    {
        [self setupRenderPassDescriptorForTexture: drawable.texture];
    }
    
    return _renderPassDescriptor;
}

-(void)initCommon
{
    self.opaque                     = YES;
    self.backgroundColor            = nil;
    _metalLayer                     = (CAMetalLayer*) self.layer;
    _device                         = [MetalImageCmdQueue getGlobalDevice];
    _metalLayer.device              = _device;
    _metalLayer.pixelFormat         = MTLPixelFormatBGRA8Unorm;
    _metalLayer.framebufferOnly     = YES;
    
}
//////////////////////////////////////////////////////////////////////////////////////////////



//////draw filter result to view for assigned texture
-(void)setupRenderPassDescriptorForTexture:(id <MTLTexture>)textureForDraw
{
    if (nil == _renderPassDescriptor)//could be resue....
    {
        _renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
    }
    MTLRenderPassColorAttachmentDescriptor    *colorAttachment  = _renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture         = textureForDraw;
    colorAttachment.loadAction      = MTLLoadActionClear;
    colorAttachment.clearColor      = MTLClearColorMake(0.0, 1.0, 0.0, 0.8);//black
    if (_sampleCount > 1)
    {
        BOOL doUpdate               = (_msaaTexture.width != textureForDraw.width) || (_msaaTexture.height != textureForDraw.height) || (_msaaTexture.sampleCount != _sampleCount);
        if (!_msaaTexture || (_msaaTexture && doUpdate))
        {
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:textureForDraw.width height: textureForDraw.height mipmapped:NO];
            desc.textureType        = MTLTextureType2DMultisample;
            desc.sampleCount        = _sampleCount;
            _msaaTexture            = [_device newTextureWithDescriptor:desc];//load texture to gpu
        }
        colorAttachment.texture     = _msaaTexture;
        colorAttachment.resolveTexture = textureForDraw;
        colorAttachment.storeAction = MTLStoreActionMultisampleResolve;
    }
    else
    {
        colorAttachment.storeAction = MTLStoreActionStore;
    }
    
    //create depth and stencil attachments
    if (_depthPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate =     ( _depthTexture.width != textureForDraw.width)||( _depthTexture.height != textureForDraw.height )||( _depthTexture.sampleCount != _sampleCount   );
        
        if(!_depthTexture || doUpdate)
        {
            //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
            //  Then allocate one of the proper size
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _depthPixelFormat
                                                                                            width: textureForDraw.width
                                                                                           height: textureForDraw.height
                                                                                        mipmapped: NO];
            
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            
            _depthTexture = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassDepthAttachmentDescriptor *depthAttachment = _renderPassDescriptor.depthAttachment;
            depthAttachment.texture = _depthTexture;
            depthAttachment.loadAction = MTLLoadActionClear;
            depthAttachment.storeAction = MTLStoreActionDontCare;
            depthAttachment.clearDepth = 1.0;
        }
    }
    if(_stencilPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate = ( _stencilTexture.width != textureForDraw.width )||( _stencilTexture.height != textureForDraw.height )
        ||  ( _stencilTexture.sampleCount != _sampleCount   );
        
        if(!_stencilTexture || doUpdate)
        {
            //  If we need a stencil texture and don't have one, or if the depth texture we have is the wrong size
            //  Then allocate one of the proper size
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _stencilPixelFormat
                                                                                            width: textureForDraw.width
                                                                                           height: textureForDraw.height
                                                                                        mipmapped: NO];
            
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            
            _stencilTexture = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassStencilAttachmentDescriptor* stencilAttachment = _renderPassDescriptor.stencilAttachment;
            stencilAttachment.texture = _stencilTexture;
            stencilAttachment.loadAction = MTLLoadActionClear;
            stencilAttachment.storeAction = MTLStoreActionDontCare;
            stencilAttachment.clearStencil = 0;
        }
    } //stencil
}

- (id <CAMetalDrawable>)currentDrawable
{
    if (_currentDrawable == nil)
        _currentDrawable = [_metalLayer nextDrawable];
    
    return _currentDrawable;
}

- (void)display
{
    // Create autorelease pool per frame to avoid possible deadlock situations
    // because there are 3 CAMetalDrawables sitting in an autorelease pool.
    
    @autoreleasepool
    {
        // handle display changes here
        if(_layerSizeDidUpdate)
        {
            // set the metal layer to the drawable size in case orientation or size changes
            CGSize drawableSize = self.bounds.size;
            drawableSize.width  *= self.contentScaleFactor;
            drawableSize.height *= self.contentScaleFactor;
            
            _metalLayer.drawableSize = drawableSize;
            
            // renderer delegate method so renderer can resize anything if needed
            //[_delegate reshape:self];
            
            _layerSizeDidUpdate = NO;
        }
        
        // rendering delegate method to ask renderer to draw this frame's content
        [_filterDelegate filterRender: self withDrawableTexture:nil inCommandBuffer:nil];
        
        // do not retain current drawable beyond the frame.
        // There should be no strong references to this object outside of this view class
        _currentDrawable    = nil;
    }

}
- (void)releaseTextures
{
    _depthTexture                   = nil;
    _stencilTexture                 = nil;
    _msaaTexture                    = nil;
}

-(void)didMoveToWindow
{
    self.contentScaleFactor         = self.window.screen.nativeScale;
}
- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:contentScaleFactor];
    
    _layerSizeDidUpdate = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _layerSizeDidUpdate = YES;
}

@end
