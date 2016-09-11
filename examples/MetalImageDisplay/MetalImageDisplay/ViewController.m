//
//  ViewController.m
//  MetalImageDisplay
//
//  Created by xuqing on 14/7/2016.
//  Copyright © 2016 xuqing. All rights reserved.
//

#import "ViewController.h"
#import "MetalImage.h"

@interface ViewController ()
@end

@implementation ViewController
{
@private
    CADisplayLink       *_dispTimer;
    BOOL                _firstDrawOccurred;
    CFTimeInterval      _timeSinceLastDrawPreviousTime;
    BOOL                _gameLoopPaused;
    MetalImageFilter    *_filter;
}

-(id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    [self initCommon];
    
    return self;
}
// called when loaded from nib
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    
    if(self)
    {
        [self initCommon];
    }
    
    return self;
}

// called when loaded from storyboard
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if(self)
    {
        [self initCommon];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    MetalImageView *renderView2     = (MetalImageView*)self.view;
    renderView2.filterDelegate      = (MetalImageBrightnessFilter*)_filter;
    renderView2.depthPixelFormat    = MTLPixelFormatDepth32Float;
    renderView2.stencilPixelFormat  = MTLPixelFormatInvalid;
    renderView2.sampleCount         = 1;
    NSString*  picPath = [[NSBundle mainBundle] pathForResource:@"sandHouse" ofType:@"jpg"];
    METAL_FILTER_PIPELINE_STATE plinestate ;
    plinestate.depthPixelFormat             = MTLPixelFormatDepth32Float;
    plinestate.stencilPixelFormat           = MTLPixelFormatInvalid;
    plinestate.sampleCount                  = 1;
    plinestate.vertexFuncNameStr            = @"imageQuadVertex";
    plinestate.fragmentFuncNameStr          = @"imageQuadFragment";
    plinestate.computeFuncNameStr           = @"brightness";
    plinestate.textureImagePath             = picPath;
    [_filter configure:&plinestate];
    [(MetalImageView *)self.view display];
}


-(void)dispatchGameLoop
{
    _dispTimer = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(gameloop)];
    _dispTimer.frameInterval = _interval;
    [_dispTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode: NSDefaultRunLoopMode];
}

// the main game loop called by the timer above
- (void)gameloop
{
    
    // tell our delegate to update itself here.
    //[_delegate update:self];
    
    if(!_firstDrawOccurred)
    {
        // set up timing data for display since this is the first time through this loop
        _timeSinceLastDraw             = 0.0;
        _timeSinceLastDrawPreviousTime = CACurrentMediaTime();
        _firstDrawOccurred              = YES;
    }
    else
    {
        // figure out the time since we last we drew
        CFTimeInterval currentTime = CACurrentMediaTime();
        
        _timeSinceLastDraw = currentTime - _timeSinceLastDrawPreviousTime;
        
        // keep track of the time interval between draws
        _timeSinceLastDrawPreviousTime = currentTime;
    }
    
    // display (render)
    
    assert([self.view isKindOfClass:[MetalImageView class]]);
    
    // call the display method directly on the render view (setNeedsDisplay: has been disabled in the renderview by default)
    //[(MetalImageView *)self.view display];
}

- (void)stopGameLoop
{
    if(_dispTimer)
        [_dispTimer invalidate];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationDidEnterBackgroundNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationWillEnterForegroundNotification
                                                  object: nil];
    
    if(_dispTimer)
    {
        //[self stopGameLoop];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // run the game loop
    //[self dispatchGameLoop];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // end the gameloop
    [self stopGameLoop];
}
////////////////////////////////////////////////////////////

- (BOOL)isPaused
{
    return _gameLoopPaused;
}
- (void)setPaused:(BOOL)pause
{
    if(_gameLoopPaused == pause)
    {
        return;
    }
    
    if(_dispTimer)
    {
        // inform the delegate we are about to pause
        if(pause == YES)
        {
            _gameLoopPaused = pause;
            _dispTimer.paused   = YES;
            
            // ask the view to release textures until its resumed
            [(MetalImageView *)self.view releaseTextures];
        }
        else
        {
            _gameLoopPaused = pause;
            _dispTimer.paused   = NO;
        }
    }
}

- (void)didEnterBackground:(NSNotification*)notification
{
    [self setPaused:YES];
}

- (void)willEnterForeground:(NSNotification*)notification
{
    [self setPaused:NO];
}


-(void)initCommon
{
    _filter = [MetalImageBrightnessFilter new];
    //  Register notifications to start/stop drawing as this app moves into the background
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didEnterBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willEnterForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    
    _interval = 1;
}

@end
