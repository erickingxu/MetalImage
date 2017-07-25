//
//  MetalImageToneCurveFilter.m
//  MetalImage
//
//  Created by erickingxu on 22/7/2017.
//  Copyright © 2017 erickingxu. All rights reserved.
//  Refer to :GPUImageToneCurveFilter and adobe photoshop api document

#import "MetalImageToneCurveFilter.h"
#import <simd/simd.h>
//////////////////////////////////////////Parse acv curve file/////////////////////////////////////////////
@interface parseACVFile : NSObject
{
    short version;
    short totalCurves;
    
    NSArray *rgbCompositeCurvePoints;
    NSArray *redCurvePoints;
    NSArray *greenCurvePoints;
    NSArray *blueCurvePoints;
}

@property(strong,nonatomic) NSArray *rgbCompositeCurvePoints;
@property(strong,nonatomic) NSArray *redCurvePoints;
@property(strong,nonatomic) NSArray *greenCurvePoints;
@property(strong,nonatomic) NSArray *blueCurvePoints;

- (id) initWithACVFileData:(NSData*)data;


unsigned short int16WithBytes(Byte* bytes);
@end

@implementation parseACVFile

@synthesize rgbCompositeCurvePoints, redCurvePoints, greenCurvePoints, blueCurvePoints;

- (id) initWithACVFileData:(NSData *)data
{
    self = [super init];
    if (self != nil)
    {
        if (data.length == 0)
        {
            NSLog(@"failed to init ACVFile with data:%@", data);
            
            return self;
        }
        
        Byte* rawBytes = (Byte*) [data bytes];
        version        = int16WithBytes(rawBytes);
        rawBytes+=2;
        
        totalCurves    = int16WithBytes(rawBytes);
        rawBytes+=2;
        
        NSMutableArray *curves = [NSMutableArray new];
        
        float pointRate = (1.0 / 255);
        // The following is the data for each curve specified by count above
        for (NSInteger x = 0; x<totalCurves; x++)
        {
            unsigned short pointCount = int16WithBytes(rawBytes);
            rawBytes+=2;
            
            NSMutableArray *points = [NSMutableArray new];
            // point count * 4
            // Curve points. Each curve point is a pair of short integers where
            // the first number is the output value (vertical coordinate on the
            // Curves dialog graph) and the second is the input value. All coordinates have range 0 to 255.
            for (NSInteger y = 0; y<pointCount; y++)
            {
                unsigned short yl = int16WithBytes(rawBytes);
                rawBytes+=2;
                unsigned short xl = int16WithBytes(rawBytes);
                rawBytes+=2;

                [points addObject:[NSValue valueWithCGSize:CGSizeMake(xl * pointRate, yl * pointRate)]];
            }
            [curves addObject:points];
        }
        rgbCompositeCurvePoints = [curves objectAtIndex:0];
        redCurvePoints = [curves objectAtIndex:1];
        greenCurvePoints = [curves objectAtIndex:2];
        blueCurvePoints = [curves objectAtIndex:3];
    }
    return self;
}

unsigned short int16WithBytes(Byte* bytes)
{
    uint16_t result;
    memcpy(&result, bytes, sizeof(result));
    return CFSwapInt16BigToHost(result);
}
@end
///////////////////////////////////////////////////////////////////////////////////////
@implementation MetalImageToneCurveFilter
{
    id <MTLBuffer>          _curveBuffer;

    float            toneCurveArray[768];
    
    NSArray *_redCurve, *_greenCurve, *_blueCurve, *_rgbCompositeCurve;
    NSArray *_redControlPoints ,*_greenControlPoints, *_blueControlPoints, *_rgbCompositeControlPoints;
}


-(id)init
{
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"imgToneCurve";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    
    if (!self.filterDevice )
    {
        return nil;
    }
    
    NSArray *defaultCurve = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)], nil];

    [self setRgbCompositeControlPoints:defaultCurve];
    [self setRedControlPoints:defaultCurve];
    [self setGreenControlPoints:defaultCurve];
    [self setBlueControlPoints:defaultCurve];
    defaultCurve = nil;
    
    
    return self;
}

///// This pulls in Adobe ACV curve files to specify the tone curve
- (id)initWithACVData:(NSData *)data
{
    METAL_PIPELINE_STATE peline ;
    peline.depthPixelFormat   =  MTLPixelFormatDepth32Float;
    peline.stencilPixelFormat =  MTLPixelFormatInvalid;
    peline.orient             =  kMetalImageNoRotation;
    peline.sampleCount        =  1;
    peline.computeFuncNameStr =  @"imgToneCurve";
    if (!(self = [super initWithMetalPipeline:&peline]))
    {
        return nil;
    }
    
    if (!self.filterDevice )
    {
        return nil;
    }
    
   parseACVFile *curve = [[parseACVFile alloc] initWithACVFileData:data];
    
    [self setRgbCompositeControlPoints:curve.rgbCompositeCurvePoints];
    [self setRedControlPoints:curve.redCurvePoints];
    [self setGreenControlPoints:curve.greenCurvePoints];
    [self setBlueControlPoints:curve.blueCurvePoints];
    
    curve = nil;
    
    
    return self;
}


//- (void)dealloc
//{
//    free(toneCurveArray);
//}


/////////////////////////Metal func for calculate tone curve ////////////
-(void)caculateWithCommandBuffer:(id <MTLCommandBuffer>)commandBuffer
{
    
    if (commandBuffer && _caclpipelineState)
    {
        id <MTLComputeCommandEncoder>  cmputEncoder = [commandBuffer computeCommandEncoder];
        if (cmputEncoder)
        {
            [cmputEncoder  setComputePipelineState:_caclpipelineState];
            [cmputEncoder  setTexture: firstInputTexture.texture atIndex:0];
            [cmputEncoder  setTexture: outputTexture.texture atIndex:1];
            [cmputEncoder  setBuffer:  _curveBuffer offset:0 atIndex:0];
            [cmputEncoder  dispatchThreadgroups:_threadGroupCount threadsPerThreadgroup:_threadGroupSize];
            [cmputEncoder  endEncoding];
            
        }
    }
    //end if
}

///////////////////////////Parse acv data func in private//////////////////

- (id)initWithACVURL:(NSURL*)curveFileURL
{
    NSData* fileData = [NSData dataWithContentsOfURL:curveFileURL];
    return [self initWithACVData:fileData];
}

- (void)setPointsWithACV:(NSString*)curveFilename
{
    [self setPointsWithACVURL:[[NSBundle mainBundle] URLForResource:curveFilename withExtension:@"acv"]];
}

- (void)setPointsWithACVURL:(NSURL*)curveFileURL
{
    NSData* fileData = [NSData dataWithContentsOfURL:curveFileURL];
    parseACVFile *curve = [[parseACVFile alloc] initWithACVFileData:fileData];
    
    [self setRgbCompositeControlPoints:curve.rgbCompositeCurvePoints];
    [self setRedControlPoints:curve.redCurvePoints];
    [self setGreenControlPoints:curve.greenCurvePoints];
    [self setBlueControlPoints:curve.blueCurvePoints];
    
    curve = nil;
}

#pragma mark -
#pragma mark Curve calculation

- (NSArray *)getPreparedSplineCurve:(NSArray *)points
{
    if (points && [points count] > 0)
    {
        // Sort the array.
        NSArray *sortedPoints = [points sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {

            float x1 = [(NSValue *)a CGPointValue].x;
            float x2 = [(NSValue *)b CGPointValue].x;
            if (x1 > x2)
            {
                return NSOrderedDescending;
            }
            else if (x1 < x2)
            {
                return NSOrderedAscending;
            }
            else
            {
                return NSOrderedSame;
            }
        }];
        
        // Convert from (0, 1) to (0, 255).
        NSMutableArray *convertedPoints = [NSMutableArray arrayWithCapacity:[sortedPoints count]];
        for (int i=0; i<[points count]; i++){

            CGPoint point = [[sortedPoints objectAtIndex:i] CGPointValue];
            point.x = point.x * 255;
            point.y = point.y * 255;
            

            [convertedPoints addObject:[NSValue valueWithCGPoint:point]];
        }
        
        
        NSMutableArray *splinePoints = [self splineCurve:convertedPoints];
        
        // If we have a first point like (0.3, 0) we'll be missing some points at the beginning
        // that should be 0.

        CGPoint firstSplinePoint = [[splinePoints objectAtIndex:0] CGPointValue];
        
        if (firstSplinePoint.x > 0) {
            for (int i=firstSplinePoint.x; i >= 0; i--) {
                CGPoint newCGPoint = CGPointMake(i, 0);
                [splinePoints insertObject:[NSValue valueWithCGPoint:newCGPoint] atIndex:0];
            }
        }
        
        // Insert points similarly at the end, if necessary.

        CGPoint lastSplinePoint = [[splinePoints lastObject] CGPointValue];
        
        if (lastSplinePoint.x < 255) {
            for (int i = lastSplinePoint.x + 1; i <= 255; i++) {
                CGPoint newCGPoint = CGPointMake(i, 255);
                [splinePoints addObject:[NSValue valueWithCGPoint:newCGPoint]];
            }
        }
        // Prepare the spline points.
        NSMutableArray *preparedSplinePoints = [NSMutableArray arrayWithCapacity:[splinePoints count]];
        for (int i=0; i<[splinePoints count]; i++)
        {

            CGPoint newPoint = [[splinePoints objectAtIndex:i] CGPointValue];
            CGPoint origPoint = CGPointMake(newPoint.x, newPoint.x);
            
            float distance = sqrt(pow((origPoint.x - newPoint.x), 2.0) + pow((origPoint.y - newPoint.y), 2.0));
            
            if (origPoint.y > newPoint.y)
            {
                distance = -distance;
            }
            
            [preparedSplinePoints addObject:[NSNumber numberWithFloat:distance]];
        }
        
        return preparedSplinePoints;
    }
    
    return nil;
}


- (NSMutableArray *)splineCurve:(NSArray *)points
{
    NSMutableArray *sdA = [self secondDerivative:points];
    
    // [points count] is equal to [sdA count]
    NSInteger n = [sdA count];
    if (n < 1)
    {
        return nil;
    }
    double sd[n];
    
    // From NSMutableArray to sd[n];
    for (int i=0; i<n; i++)
    {
        sd[i] = [[sdA objectAtIndex:i] doubleValue];
    }
    
    
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:(n+1)];
    
    for(int i=0; i<n-1 ; i++)
    {

        CGPoint cur = [[points objectAtIndex:i] CGPointValue];
        CGPoint next = [[points objectAtIndex:(i+1)] CGPointValue];
        for(int x=cur.x;x<(int)next.x;x++)
        {
            double t = (double)(x-cur.x)/(next.x-cur.x);
            
            double a = 1-t;
            double b = t;
            double h = next.x-cur.x;
            
            double y= a*cur.y + b*next.y + (h*h/6)*( (a*a*a-a)*sd[i]+ (b*b*b-b)*sd[i+1] );
            
            if (y > 255.0)
            {
                y = 255.0;
            }
            else if (y < 0.0)
            {
                y = 0.0;
            }

            [output addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        }
    }
    
    // The above always misses the last point because the last point is the last next, so we approach but don't equal it.
    [output addObject:[points lastObject]];
    return output;
}

- (NSMutableArray *)secondDerivative:(NSArray *)points
{
    const NSInteger n = [points count];
    if ((n <= 0) || (n == 1))
    {
        return nil;
    }
    
    double matrix[n][3];
    double result[n];
    matrix[0][1]=1;
    // What about matrix[0][1] and matrix[0][0]? Assuming 0 for now (Brad L.)
    matrix[0][0]=0;
    matrix[0][2]=0;
    
    for(int i=1;i<n-1;i++)
    {

        CGPoint P1 = [[points objectAtIndex:(i-1)] CGPointValue];
        CGPoint P2 = [[points objectAtIndex:i] CGPointValue];
        CGPoint P3 = [[points objectAtIndex:(i+1)] CGPointValue];
        
        matrix[i][0]=(double)(P2.x-P1.x)/6;
        matrix[i][1]=(double)(P3.x-P1.x)/3;
        matrix[i][2]=(double)(P3.x-P2.x)/6;
        result[i]=(double)(P3.y-P2.y)/(P3.x-P2.x) - (double)(P2.y-P1.y)/(P2.x-P1.x);
    }
    
    // What about result[0] and result[n-1]? Assuming 0 for now (Brad L.)
    result[0] = 0;
    result[n-1] = 0;
    
    matrix[n-1][1]=1;
    // What about matrix[n-1][0] and matrix[n-1][2]? For now, assuming they are 0 (Brad L.)
    matrix[n-1][0]=0;
    matrix[n-1][2]=0;
    
    // solving pass1 (up->down)
    for(int i=1;i<n;i++)
    {
        double k = matrix[i][0]/matrix[i-1][1];
        matrix[i][1] -= k*matrix[i-1][2];
        matrix[i][0] = 0;
        result[i] -= k*result[i-1];
    }
    // solving pass2 (down->up)
    for(NSInteger i=n-2;i>=0;i--)
    {
        double k = matrix[i][2]/matrix[i+1][1];
        matrix[i][1] -= k*matrix[i+1][0];
        matrix[i][2] = 0;
        result[i] -= k*result[i+1];
    }
    
    double y2[n];
    for(int i=0;i<n;i++) y2[i]=result[i]/matrix[i][1];
    
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:n];
    for (int i=0;i<n;i++)
    {
        [output addObject:[NSNumber numberWithDouble:y2[i]]];
    }
    
    return output;
}

- (void)updateToneCurveBuffer
{
    
    
        if ( ([_redCurve count] >= 256) && ([_greenCurve count] >= 256) && ([_blueCurve count] >= 256) && ([_rgbCompositeCurve count] >= 256))
        {

            for (unsigned int currentCurveIndex = 0; currentCurveIndex < 256; currentCurveIndex++)
            {
                // BGRA for upload to texture

                GLubyte b = fmin(fmax(currentCurveIndex + [[_blueCurve objectAtIndex:currentCurveIndex] floatValue], 0), 255);
                
                toneCurveArray[currentCurveIndex * 3 ] = (float)fmin(fmax(b + [[_rgbCompositeCurve objectAtIndex:b] floatValue], 0), 255) / 255.0;

                GLubyte g = fmin(fmax(currentCurveIndex + [[_greenCurve objectAtIndex:currentCurveIndex] floatValue], 0), 255);
                toneCurveArray[currentCurveIndex * 3 + 1] = (float) fmin(fmax(g + [[_rgbCompositeCurve objectAtIndex:g] floatValue], 0), 255) / 255.0;
                
                GLubyte r = fmin(fmax(currentCurveIndex + [[_redCurve objectAtIndex:currentCurveIndex] floatValue], 0), 255);
                toneCurveArray[currentCurveIndex * 3 + 2 ] = (float) fmin(fmax(r + [[_rgbCompositeCurve objectAtIndex:r] floatValue], 0), 255) / 255.0;
                
            }
            unsigned int sz = 256 * 3 * sizeof(float);
            _curveBuffer   = [self.filterDevice newBufferWithBytes:&toneCurveArray length: sz  options:MTLResourceStorageModeShared];
            if (!_curveBuffer)
            {
                NSLog(@"Error for create buffer");
            }
        }
    
    
}

///////////////////////////Parse acv data func in END//////////////////
#pragma mark -
#pragma mark Accessors

- (void)setRGBControlPoints:(NSArray *)points
{
    _redControlPoints = [points copy];
    _redCurve = [self getPreparedSplineCurve:_redControlPoints];
    
    _greenControlPoints = [points copy];
    _greenCurve = [self getPreparedSplineCurve:_greenControlPoints];
    
    _blueControlPoints = [points copy];
    _blueCurve = [self getPreparedSplineCurve:_blueControlPoints];
    
    [self updateToneCurveBuffer];
}


- (void)setRgbCompositeControlPoints:(NSArray *)newValue
{
    _rgbCompositeControlPoints = [newValue copy];
    _rgbCompositeCurve = [self getPreparedSplineCurve:_rgbCompositeControlPoints];
    
    [self updateToneCurveBuffer];
}


- (void)setRedControlPoints:(NSArray *)newValue;
{
    _redControlPoints = [newValue copy];
    _redCurve = [self getPreparedSplineCurve:_redControlPoints];
    
    [self updateToneCurveBuffer];
}


- (void)setGreenControlPoints:(NSArray *)newValue
{
    _greenControlPoints = [newValue copy];
    _greenCurve = [self getPreparedSplineCurve:_greenControlPoints];
    
    [self updateToneCurveBuffer];
}


- (void)setBlueControlPoints:(NSArray *)newValue
{
    _blueControlPoints = [newValue copy];
    _blueCurve = [self getPreparedSplineCurve:_blueControlPoints];
    
    [self updateToneCurveBuffer];
}

@end


