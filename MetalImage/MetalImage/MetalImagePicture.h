//
//  MetalImagePicture.h
//  MetalImage
//
//  Created by xuqing on 3/8/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MetalImageOutput.h"

@interface MetalImagePicture : MetalImageOutput
{
    CGSize pixelSize;
    BOOL   hasdProcessed;
    dispatch_semaphore_t    imageUpdateSemaphore;
    id <MTLDevice>          imgDevice;
}

-(id)initWithImage:(UIImage*)img;
-(id)initWithCGImage:(CGImageRef)image  smoothlyScaleOutput: (BOOL)bSmoothly;

-(void)processImage;

-(BOOL)processImageWithCompletionHandler:(void (^)(void))completionFunc;
@end
