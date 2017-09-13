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
    MetalImageOutput<MetalImageInput> *filter, *filter1;
    
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
    vc      = [[MetalImageVideoCamera alloc] init];
    filter  = [[MetalImageSketchFilter alloc] init];
    filter1 = [[MetalImagePointSpirit alloc] init];
    //filter = [[MetalImageCropFilter alloc] initWithCropRegion:CGRectMake(0.125, 0.125, 0.75, 0.75)];
//    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"Amaro" withExtension:@"acv"];
//    filter = [[MetalImageToneCurveFilter alloc] initWithACVURL:fileUrl];
    MetalImageView*  imageView = (MetalImageView*)self.view;
    imageView.inputRotation  = kMetalImageRotateLeft;
    [vc addTarget:filter];
    [filter addTarget:filter1];
    [filter1 addTarget:imageView];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
