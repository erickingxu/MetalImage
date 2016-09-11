//
//  ViewController.m
//  MetalImageFilter
//
//  Created by xuqing on 3/8/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//
#import <simd/simd.h>

#import "MetalImage.h"

#import "ViewController.h"


@interface ViewController ()
{
    MetalImagePicture *sourcePic;
    MetalImageOutput<MetalImageInput>  *filter;
    MetalImageOutput<MetalImageInput>  *filter1;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];
    [self setupFilterImageDisplay];
}

-(void)setupFilterImageDisplay
{
    UIImage *img = [UIImage imageNamed:@"JonSnow.jpg"];
    sourcePic  = [[MetalImagePicture alloc] initWithImage:img];
    if(![sourcePic fireOn])
    {
        NSLog(@"Can not make filter fire on!");
    }
    filter     = [[MetalImageGaussianFilter alloc] init];
    //filter1    = [[MetalImageBrightnessFilter alloc] init];
    
    MetalImageView*  imageView = (MetalImageView*)self.view;
    [sourcePic addTarget:filter];
    //[filter addTarget:filter1];
    [filter addTarget:imageView];

    [sourcePic processImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
