//
//  ViewController.m
//  MetalVideoFilter
//
//  Created by erickingxu on 10/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import "ViewController.h"
#import "MetalImage.h"

@interface ViewController ()
{
    MetalImageVideoCamera* vc;
    MetalImageOutput<MetalImageInput> *filter;
    
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self startupVideo];
}

-(void)startupVideo
{
    vc     = [[MetalImageVideoCamera alloc] init];
    filter    = [[MetalImageBeautyFilter alloc] init];
filter = [[MetalImageCropFilter alloc] initWithCropRegion:CGRectMake(0.125, 0.125, 0.75, 0.75)];
    
    MetalImageView*  imageView = (MetalImageView*)self.view;
    imageView.inputRotation  = kMetalImageRotateLeft;
    [vc addTarget:filter];

    [filter addTarget:imageView];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
