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
typedef struct _ModelHeadPose
{
    float           viewMat[ 16 ];
    float           projectMat[ 16 ];
} ModelPose;

typedef struct _FaceFrameData
{
    float           facePoints[ 106 * 2 ];            /* [f0x, f0y, f1x, f1y, f2x, f2y, ...]. */
    uint32_t        facePointsCount;
    bool            isMouthOpen;
    bool            eyeBlink;
    bool            isHeadYaw;
    bool            isHeadPitch;
    bool            isBrowJump;
    float           openMouthIntensity;
    ModelPose       headPose;
} FaceFrameData;

typedef struct _AttachmentDataArr
{
    FaceFrameData   faceItemArr[ 5 ];
    uint32_t        faceCount;
} AttachmentDataArr;

typedef struct _Texture_FrameData
{
    uint8_t*        imageData;    /* [input] Image raw buffer, some filter may need this, most of the filter is set to NULL. */
    uint32_t        width;               /* [input] width of image data. */
    uint32_t        height;              /* [input] height of image data. */
    uint32_t        widthStep;           /* [input] The number of bytes in per line of the image data. */
    uint32_t        format;              /* [input] Format of input image data, One of the RGBA32, NV12, BGR24, BGRA32. */
    AttachmentDataArr attachFrameDataArr; /* [input] [output] Face alignment data. */
    
} Texture_FrameData;

#endif /* MetalImageOrigin_h */
