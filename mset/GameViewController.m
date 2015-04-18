//
//  GameViewController.m
//  mset
//
//  Created by Jonathan Slater on 16/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@interface GameViewController ()

@property (strong, nonatomic) EAGLContext* context;
@property (nonatomic, strong) NSObject<Fractal>* fractal;
@property (nonatomic, strong) Renderer* renderer;

@end

@implementation GameViewController {
    BOOL _requireCompute;
}

-(void)viewDidLoad {
    [super viewDidLoad];

    self.context = [self createBestEAGLContext];
    if (self.context == nil) {
        [NSException raise:ExceptionLogicError format:@"invalid OpenGL ES Context"];
    }
    GLKView* view = (GLKView*) self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.preferredFramesPerSecond = 60;
    self.multitouchEnabled = true;

    [self setupGL];

    @try {
//        CGRect screenBounds = [[UIScreen mainScreen] bounds];
//        CGFloat screenScale = [[UIScreen mainScreen] scale];
//        CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
        CGSize screenSize = CGSizeMake(1024, 768);
        self.renderer = [Renderer rendererWithWidth:screenSize.width height:screenSize.height];
        _requireCompute = YES;

        self.fractal = [[MandelbrotSet alloc] init];
    }
    @catch (NSException* ex) {
        NSLog(@"exception: '%@', reason: '%@'", ex.name, ex.reason);
    }
    @finally {

    }
}

-(EAGLContext*)createBestEAGLContext {
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (context == nil) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    return context;
}

-(void)dealloc {
    [self tearDownGL];

    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;

        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)setupGL {
    [EAGLContext setCurrentContext:self.context];
}

-(void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark - GLKView and GLKViewController delegate methods

-(void)compute
{
    
}

-(void)update {
    if (_requireCompute) {
        double centerX = -0.5;
        double centerY = 0;
        double sizeX = 4;
        NSInteger maxIterations = 100;

        self.fractal.fractalDescriptor = [FractalDescriptor fractalDescriptorWithXMin:centerX - (sizeX / 2)
                                                                                 xMax:centerX + (sizeX / 2)
                                                                                 yMin:centerY - (sizeX / 2)
                                                                                 yMax:centerY + (sizeX / 2)
                                                                         escapeRadius:2
                                                                        maxIterations:maxIterations];
        [self.fractal compute:self.renderer.imageData
                        width:self.renderer.imagewidth
                       height:self.renderer.imageHeight
                   updateDraw:^() {
                       [self.renderer updateImage];
                   }];
        _requireCompute = NO;
    }
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    [self.renderer render];
}

-(void)setMultitouchEnabled:(BOOL)multitouchEnabled {
    self.view.multipleTouchEnabled = multitouchEnabled;
}

-(BOOL)multitouchEnabled {
    return self.view.multipleTouchEnabled;
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    [self processTouchEvent:event];
}

-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    [self processTouchEvent:event];
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    [self processTouchEvent:event];
}

-(void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
//    _lastTouchTimestamp -= 0.0001f; // cancelled touch events have an old timestamp -> workaround
    [self processTouchEvent:event];
}

-(void)processTouchEvent:(UIEvent*)event {
//    if (!self.paused && _lastTouchTimestamp != event.timestamp)
//    {
//        @autoreleasepool
//        {
//            CGSize viewSize = self.view.bounds.size;
//            float xConversion = _stage.width / viewSize.width;
//            float yConversion = _stage.height / viewSize.height;
//
//            // convert to SPTouches and forward to stage
//            NSMutableSet *touches = [NSMutableSet set];
//            double now = CACurrentMediaTime();
//            for (UITouch *uiTouch in [event touchesForView:self.view])
//            {
//                CGPoint location = [uiTouch locationInView:self.view];
//                CGPoint previousLocation = [uiTouch previousLocationInView:self.view];
//                SPTouch *touch = [SPTouch touch];
//                touch.timestamp = now; // timestamp of uiTouch not compatible to Sparrow timestamp
//                touch.globalX = location.x * xConversion;
//                touch.globalY = location.y * yConversion;
//                touch.previousGlobalX = previousLocation.x * xConversion;
//                touch.previousGlobalY = previousLocation.y * yConversion;
//                touch.tapCount = (int)uiTouch.tapCount;
//                touch.phase = (SPTouchPhase)uiTouch.phase;
//                touch.nativeTouch = uiTouch;
//                [touches addObject:touch];
//            }
//            [_touchProcessor processTouches:touches];
//            _lastTouchTimestamp = event.timestamp;
//        }
//    }
}

@end
