//
//  ViewController.h
//  MetalVideoFilter
//
//  Created by erickingxu on 10/8/2016.
//  Copyright © 2016 erickingxu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController{
    IBOutlet UISegmentedControl *algoChoice;
}
@property(nonatomic,retain)UISegmentedControl *algoChoice;

-(IBAction) segmentedControlIndexChanged:(id)sender;
@end

