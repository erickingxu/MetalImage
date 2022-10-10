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
    int algo_state;
}
@end

@implementation ViewController
@synthesize algoChoice;


- (void)viewDidLoad {
    [super viewDidLoad];
    algo_state = 0;
    // Do any additional setup after loading the view, typically from a nib.
    [self startupVideo];
}
-(IBAction) segmentedControlIndexChanged:(id)sender{
   NSInteger algo_st = [(UISegmentedControl*)sender selectedSegmentIndex];
    algo_state = algo_st;
    MetalImageView*  imageView = (MetalImageView*)self.view;
    imageView.inputRotation  = kMetalImageRotateLeft;
    if (algo_state == 0) {
        [vc addTarget:imageView];
    }
    else if (algo_state == 1){
        [vc addTarget:filter];
        [filter addTarget:imageView];
    }
}
-(void)startupVideo
{
    vc      = [[MetalImageVideoCamera alloc] init];
    if (@available(iOS 11.0, *)) {
        filter  = [[MetalImageGammaFilter alloc] init];
    } else {
        // Fallback on earlier versions
        NSLog(@"....xxxx....");
    }
    MetalImageView*  imageView = (MetalImageView*)self.view;
    imageView.inputRotation  = kMetalImageRotateLeft;
    if (algo_state == 0) {
        [vc addTarget:imageView];
    }
    else if (algo_state == 1){
        [vc addTarget:filter];
        [filter addTarget:imageView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
