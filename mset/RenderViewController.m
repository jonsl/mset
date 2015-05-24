//
//  RenderViewController.m
//  mset
//
//  Created by Jonathan Slater on 22/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

static float const ScreenWidth = 1024.f;
static Real InitialRealCentre = -0.5;
static Real InitialRealWidth = 4;


@interface RenderViewController()

@property (nonatomic, strong) GestureViewController* gameViewController;
@property (nonatomic, strong) EAGLContext* eaglContext;
@property (nonatomic, assign) GLKMatrix4 modelViewMatrix;
@property (nonatomic, strong) NSObject<Fractal>* fractal;
@property (nonatomic, strong) ComplexPlane* complexPlane;

@end

@implementation RenderViewController {
    GLKMatrix4 _projectionMatrix;
    CGSize _screenSize;
    CGFloat _aspect;

    BOOL _pendingCompute;

    GLKMatrix4 _translateMatrix;
    GLKMatrix4 _scaleMatrix;
    GLKMatrix4 _rotateMatrix;

    CGPoint _initialPosition;
    CGFloat _initialScale;
    CGFloat _initialRotation;
}

-(void)viewDidLoad {
    [super viewDidLoad];

    self.eaglContext = [self createBestEAGLContext];
    if (self.eaglContext == nil) {
        [NSException raise:ExceptionLogicError format:@"invalid OpenGL ES Context"];
    }
    [EAGLContext setCurrentContext:self.eaglContext];

    GLKView* view = (GLKView*)self.view;
    view.context = self.eaglContext;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.preferredFramesPerSecond = 30;

    _initialPosition = CGPointMake(0, 0);
    _initialScale = 1.f;
    _initialRotation = 0.f;

    [self initialiseMatrices];

    @try {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);

        _aspect = screenSize.width / screenSize.height;
        _screenSize = CGSizeMake(ScreenWidth, ScreenWidth / _aspect);
        _projectionMatrix = GLKMatrix4MakeOrtho(0, _screenSize.width, 0, _screenSize.height, 0.f, 1.f);

        self.fractal = [MandelbrotSet mandelbrotSet];
        [self initialiseComplexPlane];

        _pendingCompute = YES;
    }
    @catch (NSException* ex) {
        NSLog(@"exception: '%@', reason: '%@'", ex.name, ex.reason);
    }
    @finally {

    }
}

-(void)initialiseComplexPlane {
    Real rHalfExtent = 0.5 * InitialRealWidth;
    Real iHalfExtent = 0.5 * InitialRealWidth / _aspect;
    CPPoint cOrigin, rMaxiMin, rMiniMax;
    cOrigin.r = InitialRealCentre - rHalfExtent;
    cOrigin.i = -iHalfExtent;
    rMaxiMin.r = cOrigin.r + InitialRealWidth;
    rMaxiMin.i = -iHalfExtent;
    rMiniMax.r = cOrigin.r;
    rMiniMax.i = +iHalfExtent;
    self.fractal.complexPlane = self.complexPlane = [ComplexPlane complexPlaneWithOrigin:cOrigin rMaxiMin:rMaxiMin rMiniMax:rMiniMax];
}

-(void)didMoveToParentViewController:(UIViewController*)parent {
    if ([parent isKindOfClass:[GestureViewController class]]) {
        self.gameViewController = (GestureViewController*)parent;
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

-(CPPoint)canvasPointToComplexPlane:(CGPoint)position {
    Real xLen = (Real)position.x / _screenSize.width;
    Real yLen = (Real)position.y / _screenSize.height;
    CPPoint pp;
    pp.r = self.fractal.complexPlane.origin.r
            + xLen * (self.fractal.complexPlane.rMaxiMin.r - self.fractal.complexPlane.origin.r)
            + yLen * (self.fractal.complexPlane.rMiniMax.r - self.fractal.complexPlane.origin.r);
    pp.i = self.fractal.complexPlane.origin.i
            + yLen * (self.fractal.complexPlane.rMiniMax.i - self.fractal.complexPlane.origin.i)
            + xLen * (self.fractal.complexPlane.rMaxiMin.i - self.fractal.complexPlane.origin.i);
    return pp;
}

-(void)screenToComplexPlane {
    // un-transform full size screen coordinates to get new screen
    bool isInvertible;
    GLKMatrix4 screenMatrix = GLKMatrix4Invert(self.modelViewMatrix, &isInvertible);
    GLKVector4 vOrigin = GLKMatrix4MultiplyVector4(screenMatrix, GLKVector4Make(0, 0, 0, 1.f));
    GLKVector4 vCrMaxiMin = GLKMatrix4MultiplyVector4(screenMatrix, GLKVector4Make(_screenSize.width, 0, 0, 1.f));
    GLKVector4 vCrMiniMax = GLKMatrix4MultiplyVector4(screenMatrix, GLKVector4Make(0, _screenSize.height, 0, 1.f));
    // convert to complex plane
    CPPoint cOrigin = [self canvasPointToComplexPlane:CGPointMake(vOrigin.x, vOrigin.y)];
    CPPoint crMaxiMin = [self canvasPointToComplexPlane:CGPointMake(vCrMaxiMin.x, vCrMaxiMin.y)];
    CPPoint crMiniMax = [self canvasPointToComplexPlane:CGPointMake(vCrMiniMax.x, vCrMiniMax.y)];
    self.complexPlane = [ComplexPlane complexPlaneWithOrigin:cOrigin rMaxiMin:crMaxiMin rMiniMax:crMiniMax];
}

-(void)scheduleRecompute {
    _pendingCompute = YES;
}

-(void)compute {
    self.modelViewMatrix = GLKMatrix4Identity;

    [self.fractal updateWithComplexPlane:self.complexPlane screenSize:_screenSize];
}

-(void)update {
    if (_pendingCompute) {
        _pendingCompute = NO;
        self.modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(GLKMatrix4Multiply(_scaleMatrix, _rotateMatrix), _translateMatrix), self.modelViewMatrix);
        [self screenToComplexPlane];

        _translateMatrix = GLKMatrix4Identity;
        _rotateMatrix = GLKMatrix4Identity;
        _scaleMatrix = GLKMatrix4Identity;

        [self compute];
    }
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    [self.fractal renderWithMvpMatrix:self.modelViewMatrix alpha:1.f];
}

-(CGPoint)touchToCanvas:(CGPoint)touch {
    return CGPointMake(touch.x, _screenSize.height - touch.y);
}

-(void)initialiseMatrices {
    _translateMatrix = GLKMatrix4Translate(GLKMatrix4Identity, _initialPosition.x, _initialPosition.y, 0.0);
    _scaleMatrix = GLKMatrix4Scale(GLKMatrix4Identity, _initialScale, _initialScale, 1.0);
    _rotateMatrix = GLKMatrix4Rotate(GLKMatrix4Identity, _initialRotation, 0.0, 0.0, 1.0);
    self.modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(GLKMatrix4Multiply(_scaleMatrix, _rotateMatrix), _translateMatrix), GLKMatrix4Identity);

    _scaleMatrix = GLKMatrix4Identity;
    _rotateMatrix = GLKMatrix4Identity;
    _translateMatrix = GLKMatrix4Identity;
}

-(void)translate:(CGPoint)location {
//    CGPoint pt = [self touchToCanvas:location];
//    CPPoint cp = [self canvasPointToComplexPlane:pt];
//    NSLog(@"pt, cp = (%f,%f) : (%lf,%lf)", location.x, location.y, cp.r, cp.i);
//    CPPoint pt = [self touchToComplexPlane:location];
//    NSLog(@"pt = {%lf, %lf}", pt.r, pt.i);
//    _translateMatrix = GLKMatrix4Translate(_translateMatrix, -cp.r, -cp.i, 0.0);
//
    [self scheduleRecompute];
}

-(void)rotateWithCentre:(CGPoint)centre radians:(CGFloat)radians {
    CGPoint pt = [self touchToCanvas:centre];
    _rotateMatrix = GLKMatrix4Translate(_rotateMatrix, pt.x, pt.y, 0.0);
    _rotateMatrix = GLKMatrix4Rotate(_rotateMatrix, -radians, 0.0, 0.0, 1.0);
    _rotateMatrix = GLKMatrix4Translate(_rotateMatrix, -pt.x, -pt.y, 0.0);

    [self scheduleRecompute];
}

-(void)scaleWithCentre:(CGPoint)centre scale:(CGFloat)scale {
    CGPoint pt = [self touchToCanvas:centre];
    _scaleMatrix = GLKMatrix4Translate(_scaleMatrix, pt.x, pt.y, 0.0);
    _scaleMatrix = GLKMatrix4Scale(_scaleMatrix, scale, scale, 1.0);
    _scaleMatrix = GLKMatrix4Translate(_scaleMatrix, -pt.x, -pt.y, 0.0);

    [self scheduleRecompute];
}

-(void)translateEnded {
//    [self scheduleRecompute];
}

-(void)rotateEnded {
//    [self scheduleRecompute];
}

-(void)scaleEnded {
//    [self scheduleRecompute];
}

@end
