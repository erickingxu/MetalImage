//
//  MetalImageVideo.h
//  MetalImage
//
//  Created by xuqing on 26/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import <Accelerate/Accelerate.h>

#import "MetalImageCustomFilter.h"

@interface MetalImageVideo : MetalImageCustomFilter<AVCaptureVideoDataOutputSampleBufferDelegate>


@end
