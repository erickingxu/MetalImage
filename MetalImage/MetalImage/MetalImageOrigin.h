//
//  MetalImageOrigin.h
//  MetalImage
//
//  Created by ericking on 10/8/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//

#ifndef MetalImageOrigin_h
#define MetalImageOrigin_h

#import <AVFoundation/AVFoundation.h>
//////////////////////////////////////Core texture data struct for CPU-Processing///////////////////////////////
typedef struct _Model3DPose
{
    float           viewMat[ 16 ];
    float           projectMat[ 16 ];
} Model3DPose;

typedef struct _FaceFrameData
{
    float           facePoints[ 48 * 2 ];            //some like as [x0,y0,x1,y1 ...]
    uint32_t        facePointsCount;
    bool            isMouthOpen;
    bool            eyeBlink;
    bool            isHeadYaw;
    bool            isHeadPitch;
    bool            isBrowJump;
    float           openMouthIntensity;
    Model3DPose       headPose;
} FaceFrameData;

typedef struct _AttachmentDataArr
{
    FaceFrameData   faceItemArr[ 5 ];
    uint32_t        faceCount;
} AttachmentDataArr;

typedef struct _Texture_FrameData
{
    uint8_t*        imageData;
    uint32_t        width;
    uint32_t        height;
    uint32_t        widthStep;
    uint32_t        format;
    AttachmentDataArr attachFrameDataArr; //attach some cpu data for processing
    
} Texture_FrameData;

#endif /* MetalImageOrigin_h */
