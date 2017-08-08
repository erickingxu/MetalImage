//
//  MetalImageFaceShapenFilter.h
//  MetalImage
//
//  Created by xuqing on 7/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#import "MetalImageFilter.h"

@interface MetalImageFaceShapenFilter : MetalImageFilter

-(void)loadFrameData: (uint8_t*)baseAddress  withFormat:(int)fmt withWidth: (uint32_t)width withHeight: (uint32_t)height inBytesPerRow: (uint32_t)bytesPerRow;
@end
