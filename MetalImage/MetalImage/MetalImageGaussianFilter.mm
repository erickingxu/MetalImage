//
//  MetalImageGaussianFilter.m
//  MetalImage
//
//  Created by erickingxu on 27/7/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageGaussianFilter.h"

@implementation MetalImageGaussianFilter
{
    id <MTLTexture>             blurWeightTexture;
    id <MTLTexture>             weightsTexture;
    MetalImageTexture*          TempoutputTexture;
    id <MTLComputePipelineState> vertical_Caculatepipeline;
    int                         _blurRadius;
}

-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"gaussian_BlurHorizontal";
    //  gaussian_BlurHorizontal";//gaussian_BlurHorizontal,gaussian_blur_2d
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    self.radius  =  4.0;
    self.sigma   =  2.0;
    _blurRadius  = round(self.radius);
    /////////////////////////////////////////////////////////////////////////
    [self createGaussianWeightsTexture];
    TempoutputTexture = nil;
    id <MTLFunction> caculateFuncHoz   = [self.filterLibrary newFunctionWithName:@"gaussian_BlurVertical"];
    NSError *pError = nil;
    vertical_Caculatepipeline  = [self.filterDevice newComputePipelineStateWithFunction:caculateFuncHoz error:&pError];
    
    return self;
}

- (void)setRadius:(float)radius
{
    _radius = radius;
    
}

- (void)setSigma:(float)sigma
{
    _sigma = sigma;

}

-(void)generateBlurWeightTexture
{
   
        NSAssert(self.radius >= 0, @"Blur radius must be non-negative");
        
        const float radius = self.radius;
        const float sigma  = self.sigma;
        const int   size   = (round(radius) * 2) + 1;
        
        float delta = 0;
        float expScale = 0;
        if (radius > 0.0)
        {
            delta = (radius * 2) / (size - 1);;
            expScale = -1 / (2 * sigma * sigma);
        }
        
        float *weights = (float*)malloc(sizeof(float) * size * size);
        
        float weightSum = 0;
        float y = -radius;
        for (int j = 0; j < size; ++j, y += delta)
        {
            float x = -radius;
            
            for (int i = 0; i < size; ++i, x += delta)
            {
                float weight = expf((x * x + y * y) * expScale);
                weights[j * size + i] = weight;
                weightSum += weight;
            }
        }
        
        const float weightScale = 1 / weightSum;
        for (int j = 0; j < size; ++j)
        {
            for (int i = 0; i < size; ++i)
            {
                weights[j * size + i] *= weightScale;
            }
        }
        
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR32Float
                                                                                                     width:size
                                                                                                    height:size
                                                                                                 mipmapped:NO];
        
        blurWeightTexture = [self.filterDevice newTextureWithDescriptor:textureDescriptor];
        
        MTLRegion region = MTLRegionMake2D(0, 0, size, size);
        [blurWeightTexture replaceRegion:region mipmapLevel:0 withBytes:weights bytesPerRow:sizeof(float) * size];
        
        free(weights);
}

-(void)createGaussianWeightsTexture
{
    
    float *standardGaussianWeights = (float*)malloc((_blurRadius + 1)*sizeof(float));
    float sumOfWeights = 0.0;
    for (int  currentGaussianWeightIndex = 0; currentGaussianWeightIndex < _blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * M_PI * pow(_sigma, 2.0))) * exp(-pow(currentGaussianWeightIndex, 2.0) / (2.0 * pow(_sigma, 2.0)));
        
        if (currentGaussianWeightIndex == 0)
        {
            sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
        }
        else
        {
            sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
        }
    }
    
    // Next, normalize these weights to prevent the clipping of the Gaussian curve at the end of the discrete samples from reducing luminance
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < _blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
    }
//    standardGaussianWeights[0] = 0.00;
//        standardGaussianWeights[1] = 0.01;
//        standardGaussianWeights[2] = 0.12;
//        standardGaussianWeights[3] = 0.16;
//        standardGaussianWeights[4] = 0.21;
////////////
    MTLTextureDescriptor *text1DDescriptor = [[MTLTextureDescriptor alloc] init];
    text1DDescriptor.textureType = MTLTextureType1D;
    text1DDescriptor.pixelFormat = MTLPixelFormatR32Float;
    text1DDescriptor.width       = _blurRadius + 1;
    text1DDescriptor.height      = 1;
    text1DDescriptor.depth       = 1;
    weightsTexture  = [self.filterDevice newTextureWithDescriptor:text1DDescriptor];
    MTLRegion regionw = MTLRegionMake1D(0, _blurRadius + 1);
    [weightsTexture replaceRegion:regionw mipmapLevel:0 withBytes:standardGaussianWeights bytesPerRow:sizeof(float)*(_blurRadius + 1)];
    
}

-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    if (!commandBuffer )
    {
        return;
    }
    /////////////////////////////////////////////////////////////////////////////////////////
    if (_caclpipelineState)
    {
        /////////////////////////////////
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            TempoutputTexture  = [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight:firstInputTexture.height];
            [TempoutputTexture loadTextureIntoDevice:self.filterDevice];
            
        });
        
        id <MTLComputeCommandEncoder>  cmputEncoder = [commandBuffer computeCommandEncoder];
        if (cmputEncoder)
        {
            [cmputEncoder  setComputePipelineState:_caclpipelineState];
            [cmputEncoder setTexture: firstInputTexture.texture atIndex:0];
            [cmputEncoder setTexture: TempoutputTexture.texture atIndex:1];
            [cmputEncoder setTexture: weightsTexture atIndex:2];
            [cmputEncoder dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder endEncoding];
        }
    }

    //end if
    if(vertical_Caculatepipeline)
    {
        id <MTLComputeCommandEncoder>  cmputEncoderV = [commandBuffer computeCommandEncoder];
        if (cmputEncoderV)
        {
            [cmputEncoderV  setComputePipelineState:vertical_Caculatepipeline];
            [cmputEncoderV setTexture: TempoutputTexture.texture atIndex:0];
            [cmputEncoderV setTexture: outputTexture.texture atIndex:1];
            [cmputEncoderV setTexture: weightsTexture atIndex:2];
            [cmputEncoderV dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoderV endEncoding];
            //it is ok ,algorithm need to be modified...
        }
    }
    else
    {
        outputTexture  = TempoutputTexture;
    }

    
}

@end
