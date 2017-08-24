//
//  MetalImageBeautyFilter.m
//  MetalImage
//
//  Created by erickingxu on 23/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "MetalImageBeautyFilter.h"

@implementation MetalImageBeautyFilter
{

    id <MTLTexture>              weightsTexture;
    MetalImageTexture*           GaussianOutputTexture;
    MetalImageTexture*           HighPassOutputTexture;
    MetalImageTexture*           HighPassBlurTexture;
    id <MTLComputePipelineState> vertical_Caculatepipeline;
    id <MTLComputePipelineState> beauty_Caculatepipeline;
    id <MTLComputePipelineState> beautyH_Caculatepipeline;
    int                         _blurRadius;
    float                       _sigma;
}
////////////////////////////////////////////

-(id)init
{
    
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"gaussian_HighPassHorizontal";
    peline.vertexFuncNameStr  = @"";
    peline.fragmentFuncNameStr= @"";
    //  gaussian_BlurHorizontal";//gaussian_BlurHorizontal,gaussian_blur_2d
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
  
    _blurRadius  = 4;
    _sigma       = 2.0;
    /////////////////////////////////////////////////////////////////////////
    [self createGaussianWeightsTexture];
    GaussianOutputTexture = nil;
    HighPassOutputTexture = nil;
    HighPassBlurTexture   = nil;
    
    id <MTLFunction> caculateFuncVertic   = [self.filterLibrary newFunctionWithName:@"gaussian_HighPassVertical"];
    NSError *pError = nil;
    vertical_Caculatepipeline  = [self.filterDevice newComputePipelineStateWithFunction:caculateFuncVertic error:&pError];
   
    id <MTLFunction> caculateFuncBeautyH   = [self.filterLibrary newFunctionWithName:@"blur_HighPassHorizontal"];
    beautyH_Caculatepipeline  = [self.filterDevice newComputePipelineStateWithFunction:caculateFuncBeautyH error:&pError];
    
    id <MTLFunction> caculateFuncBeauty   = [self.filterLibrary newFunctionWithName:@"beautyPass"];
    beauty_Caculatepipeline  = [self.filterDevice newComputePipelineStateWithFunction:caculateFuncBeauty error:&pError];
    return self;
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
            GaussianOutputTexture  = [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight:firstInputTexture.height];
            [GaussianOutputTexture loadTextureIntoDevice:self.filterDevice];
            HighPassOutputTexture  = [[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight:firstInputTexture.height];
            [HighPassOutputTexture loadTextureIntoDevice:self.filterDevice];
            
            HighPassBlurTexture    =[[MetalImageTexture alloc] initWithWidth:firstInputTexture.width withHeight:firstInputTexture.height];
            [HighPassBlurTexture loadTextureIntoDevice:self.filterDevice];
        });
        
        id <MTLComputeCommandEncoder>  cmputEncoder = [commandBuffer computeCommandEncoder];
        if (cmputEncoder)
        {
            [cmputEncoder  setComputePipelineState:_caclpipelineState];
            [cmputEncoder setTexture: firstInputTexture.texture atIndex:0];
            [cmputEncoder setTexture: GaussianOutputTexture.texture atIndex:1];
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
            [cmputEncoderV setTexture: GaussianOutputTexture.texture atIndex:0];
            [cmputEncoderV setTexture: firstInputTexture.texture atIndex:1];
            [cmputEncoderV setTexture: HighPassOutputTexture.texture atIndex:2];//output
            [cmputEncoderV setTexture: weightsTexture atIndex:3];
            [cmputEncoderV dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoderV endEncoding];
            //it is ok ,algorithm need to be modified...
        }
        if (beautyH_Caculatepipeline)
        {
            id <MTLComputeCommandEncoder> beatyEncoderH = [commandBuffer computeCommandEncoder];
            if (beatyEncoderH)
            {
                [beatyEncoderH setComputePipelineState:beautyH_Caculatepipeline];
                [beatyEncoderH setTexture:HighPassOutputTexture.texture atIndex:0];
                [beatyEncoderH setTexture:HighPassBlurTexture.texture atIndex:1];
                [beatyEncoderH dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
                [beatyEncoderH endEncoding];
            }
        }
        if (beauty_Caculatepipeline)
        {
            id <MTLComputeCommandEncoder> beatyEncoder = [commandBuffer computeCommandEncoder];
            if (beatyEncoder)
            {
                [beatyEncoder setComputePipelineState:beauty_Caculatepipeline];
                [beatyEncoder setTexture:HighPassBlurTexture.texture atIndex:0];
                [beatyEncoder setTexture:firstInputTexture.texture atIndex:1];
                [beatyEncoder setTexture:outputTexture.texture atIndex:2];
                [beatyEncoder dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
                [beatyEncoder endEncoding];
            }
        }
    }
    else
    {
        outputTexture  = GaussianOutputTexture;
    }
    
    
}

@end
