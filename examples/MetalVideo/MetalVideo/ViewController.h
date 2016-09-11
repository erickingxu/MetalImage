//
//  ViewController.h
//  MetalVideo
//
//  Created by xuqing on 8/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property(nonatomic, readonly) NSTimeInterval timeSinceLastDraw;
@property(nonatomic) NSUInteger  interval;
-(void)dispatchGameLoop;

@end

