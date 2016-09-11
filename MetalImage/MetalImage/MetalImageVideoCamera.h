//
//  MetalImageVideoCamera.h
//  MetalImage
//
//  Created by xuqing on 10/8/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import <Accelerate/Accelerate.h>

#import "MetalImageOutput.h"

@interface MetalImageVideoCamera : MetalImageOutput<AVCaptureVideoDataOutputSampleBufferDelegate>
{
        MetalImageRotationMode                   orient;
}
@end
