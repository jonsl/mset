//
//  GameViewController.m
//  mset
//
//  Created by Jonathan Slater on 16/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


float const ScreenWidth = 1024.f;
float const ScreenTextureSize = 1024.f;
NSInteger const MaxIterations = 2000;

@interface GameViewController ()

@property (strong, nonatomic) EAGLContext* eaglContext;
@property (strong, nonatomic) CIContext* ciContext;
@property (nonatomic, strong) NSObject<Fractal>* fractal;

@property (nonatomic, strong) Quad* screenQuad;
@property (nonatomic, assign) CGPoint screenPosition;
@property (nonatomic, strong) Quad* selectionQuad;

@property (nonatomic, assign) CGPoint dragStart;
@property (nonatomic, assign) CGPoint dragScreenStart;

@property (nonatomic, strong) FractalDescriptor* fractalDescriptor;

@end

@implementation GameViewController {
    GLKMatrix4 _projectionMatrix;
    CGSize _screenSize;
    NSUInteger _touchCount;
    NSUInteger _lastTouchCount;
    BOOL _requireCompute;
}

-(void)viewDidLoad {
    [super viewDidLoad];

    self.eaglContext = [self createBestEAGLContext];
    if (self.eaglContext == nil) {
        [NSException raise:ExceptionLogicError format:@"invalid OpenGL ES Context"];
    }

    GLKView* view = (GLKView*) self.view;
    view.context = self.eaglContext;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.preferredFramesPerSecond = 60;

    [self addGestureRecognisers];

    [self setupGL];

    @try {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);

        float aspect = screenSize.width / screenSize.height;
        _screenSize = CGSizeMake(ScreenWidth, ScreenWidth / aspect);
        _projectionMatrix = GLKMatrix4MakeOrtho(0, _screenSize.width, 0, _screenSize.height, 0.f, 1.f);

        Texture* canvasTexture = [Texture textureWithWidth:ScreenTextureSize height:ScreenTextureSize scale:1];
        self.screenQuad = [Quad quadWithTexture:canvasTexture width:canvasTexture.width height:canvasTexture.height];

        CGPoint delta = CGPointMake(self.screenQuad.width - _screenSize.width, self.screenQuad.height - _screenSize.height);
        self.screenPosition = CGPointMake(-delta.x / 2, -delta.y / 2);
//        self.screenPosition = CGPointMake(0, -300);

        self.fractalDescriptor = [FractalDescriptor fractalDescriptorWithXMin:-2.5
                                                                         xMax:+1.5
                                                                         yMin:-2.0
                                                                         yMax:+2.0
                                                                 escapeRadius:2
                                                                maxIterations:MaxIterations];

        _requireCompute = YES;

        self.fractal = [MandelbrotSet mandelbrotSet];
    }
    @catch (NSException* ex) {
        NSLog(@"exception: '%@', reason: '%@'", ex.name, ex.reason);
    }
    @finally {

    }
}

-(void)setScreenPosition:(CGPoint)screenPosition {
    float xOffset = MAX(-(self.screenQuad.width - _screenSize.width), MIN(screenPosition.x, 0));
    float yOffset = MAX(-(self.screenQuad.height - _screenSize.height), MIN(screenPosition.y, 0));
    _screenPosition = CGPointMake(xOffset, yOffset);
    self.screenQuad.position = _screenPosition;
}

-(EAGLContext*)createBestEAGLContext {
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (context == nil) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    return context;
}

-(void)dealloc {
    [self tearDownGL];

    if ([EAGLContext currentContext] == self.eaglContext) {
        [EAGLContext setCurrentContext:nil];
    }
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;

        if ([EAGLContext currentContext] == self.eaglContext) {
            [EAGLContext setCurrentContext:nil];
        }
        self.eaglContext = nil;
    }
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)setupGL {
    [EAGLContext setCurrentContext:self.eaglContext];
}

-(void)tearDownGL {
    [EAGLContext setCurrentContext:self.eaglContext];
}

#pragma mark - GLKView and GLKViewController delegate methods

-(void)compute {
    NSLog(@"recomputing with xMin: %lf, xMax: %lf, yMin: %f, yMax: %f", _fractalDescriptor.xMin, _fractalDescriptor.xMax, _fractalDescriptor.yMin, _fractalDescriptor.yMax);
    self.fractal.fractalDescriptor = self.fractalDescriptor;
    [self.fractal compute:self.screenQuad.texture.imageData
                    width:self.screenQuad.texture.width
                   height:self.screenQuad.texture.height
           executionUnits:[Configuration sharedConfiguration].executionUnits
               updateDraw:^() {
                   [self.screenQuad updateImage];
               }];
}

-(void)update {
    if (_requireCompute) {
        [self compute];
        _requireCompute = NO;
    }
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    [self.screenQuad renderWithMvpMatrix:_projectionMatrix alpha:1.f];
    [self.selectionQuad renderWithMvpMatrix:_projectionMatrix alpha:0.5f];
}

-(void)addGestureRecognisers {
    UITapGestureRecognizer* doubleTapRecg = [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(processDoubleTapGestureRecognizer:)];
    doubleTapRecg.delegate = self;
    doubleTapRecg.numberOfTapsRequired = 2;
    doubleTapRecg.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:doubleTapRecg];

    UITapGestureRecognizer* tapRecg = [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(processSingleTapGestureRecognizer:)];
    tapRecg.delegate = self;
    tapRecg.numberOfTapsRequired = 1;
    tapRecg.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapRecg];
    [tapRecg requireGestureRecognizerToFail:doubleTapRecg];

    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(processPanGestureRecognizer:)];
    [panGestureRecognizer setMaximumNumberOfTouches:2];
    [self.view addGestureRecognizer:panGestureRecognizer];
}

-(void)processDoubleTapGestureRecognizer:(UITapGestureRecognizer*)recognizer {
}

-(void)processSingleTapGestureRecognizer:(UITapGestureRecognizer*)recognizer {
}

-(void)processPanGestureRecognizer:(UIPanGestureRecognizer*)panGestureRecognizer {

    _lastTouchCount = _touchCount;
    _touchCount = [panGestureRecognizer numberOfTouches];

    if ([panGestureRecognizer state] == UIGestureRecognizerStateBegan) {
        if (_touchCount == 1) {
            [self oneTouchBegan:[panGestureRecognizer locationInView:self.view]];
        } else if (_touchCount == 2) {
            [self twoTouchesBegan:[panGestureRecognizer locationOfTouch:0 inView:self.view]
                           second:[panGestureRecognizer locationOfTouch:1 inView:self.view]];
        }
    } else if ([panGestureRecognizer state] == UIGestureRecognizerStateChanged) {
        if (_touchCount != _lastTouchCount && _touchCount == 1) {
            [self oneTouchBegan:[panGestureRecognizer locationInView:self.view]];
        } else if (_touchCount != _lastTouchCount && _touchCount == 2) {
            [self twoTouchesBegan:[panGestureRecognizer locationOfTouch:0 inView:self.view]
                           second:[panGestureRecognizer locationOfTouch:1 inView:self.view]];
        } else if (_touchCount == 1) {
            [self oneTouchMoved:[panGestureRecognizer locationInView:self.view]];
        } else if (_touchCount == 2) {
            [self twoTouchesMoved:[panGestureRecognizer locationOfTouch:0 inView:self.view]
                           second:[panGestureRecognizer locationOfTouch:1 inView:self.view]];
        }
    } else if ([panGestureRecognizer state] == UIGestureRecognizerStateEnded) {
        [self touchesEnded];
        self.selectionQuad = nil;
    } else if ([panGestureRecognizer state] == UIGestureRecognizerStateCancelled) {

        self.selectionQuad = nil;
    }
}

-(void)oneTouchBegan:(CGPoint)touch {
    _dragStart = touch;
    _dragScreenStart = _screenPosition;
}

-(PPoint)screenToWorld:(CGPoint)position {
    double xDelta = (_fractalDescriptor.xMax - _fractalDescriptor.xMin) / self.screenQuad.width;
    double yDelta = (_fractalDescriptor.yMax - _fractalDescriptor.yMin) / self.screenQuad.height;
    CGPoint pt = CGPointMake(position.x - _screenPosition.x, position.y - _screenPosition.y);
    PPoint pp;
    pp.x = _fractalDescriptor.xMin + (double) pt.x * xDelta;
    pp.y = _fractalDescriptor.yMin + (double) pt.y * yDelta;
    return pp;
}

-(void)oneTouchMoved:(CGPoint)touch {
    self.screenPosition = CGPointMake(_dragScreenStart.x - _dragStart.x + touch.x, _dragScreenStart.y + _dragStart.y - touch.y);
//    self.selectionQuad = nil;
}

-(void)twoTouchesBegan:(CGPoint)first second:(CGPoint)second {
}

-(void)twoTouchesMoved:(CGPoint)first second:(CGPoint)second {

    CGPoint pt1 = CGPointMake(first.x, _screenSize.height - first.y);
    CGPoint pt2 = CGPointMake(+(second.x - first.x), -(second.y - first.y));

    self.selectionQuad = [Quad quadWithColour:0xff width:second.x - first.x height:-(second.y - first.y)];
    self.selectionQuad.position = CGPointMake(first.x, _screenSize.height - first.y);
}

-(void)touchesEnded {
    if (self.selectionQuad != nil) {

        float xMin = MIN(self.selectionQuad.position.x, self.selectionQuad.position.x + self.selectionQuad.width);
        float xMax = MAX(self.selectionQuad.position.x, self.selectionQuad.position.x + self.selectionQuad.width);
        float yMin = MIN(self.selectionQuad.position.y, self.selectionQuad.position.y + self.selectionQuad.height);
        float yMax = MAX(self.selectionQuad.position.y, self.selectionQuad.position.y + self.selectionQuad.height);

        CGPoint bl = CGPointMake(xMin, yMin);
        CGPoint tr = CGPointMake(xMax, yMax);

        PPoint a = [self screenToWorld:bl];
        PPoint b = [self screenToWorld:tr];

        self.fractalDescriptor = [FractalDescriptor fractalDescriptorWithXMin:a.x
                                                                         xMax:b.x
                                                                         yMin:a.y
                                                                         yMax:b.y
                                                                 escapeRadius:2
                                                                maxIterations:MaxIterations];

        _requireCompute = YES;
    }
}

@end
