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
static NSInteger const DEFAULT_MAX_ITERATIONS = 256;

static Real MinFrameTime = 1.0 / 20.0;
static Real FrameTimeEpsilon = 1.0 / 20.0 - 1.0 / 22.0;

@interface RenderViewController()

@property (nonatomic, strong) EditViewController* editViewController;
@property (nonatomic, strong) EAGLContext* eaglContext;
@property (nonatomic, assign) GLKMatrix4 modelViewMatrix;
@property (nonatomic, strong) NSObject<Fractal>* fractal;

@end

@implementation RenderViewController {
    CGSize _screenSize;
    CGFloat _aspect;

    BOOL _pendingCompute;

    GLKMatrix4 _translateMatrix;
    CGPoint _translateVelocity;
    GLKMatrix4 _scaleMatrix;
    GLKMatrix4 _rotateMatrix;

    CGPoint _initialPosition;
    CGFloat _initialScale;
    CGFloat _initialRotation;

    NSInteger _maxIterations;
    NSInteger _lastIterationDelta;
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

        _maxIterations = DEFAULT_MAX_ITERATIONS;
        _lastIterationDelta = DEFAULT_MAX_ITERATIONS >> 1;

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
    self.fractal.complexPlane = [ComplexPlane complexPlaneWithOrigin:cOrigin rMaxiMin:rMaxiMin rMiniMax:rMiniMax];
}

-(void)didMoveToParentViewController:(UIViewController*)parent {
    if ([parent isKindOfClass:[EditViewController class]]) {
        self.editViewController = (EditViewController*)parent;
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

-(ComplexPlane*)createComplexPlaneWithInverseModelViewMatrix:(GLKMatrix4)inverseModelViewMatrix {
    // un-transform full size screen coordinates to get new screen
    GLKVector4 vOrigin = GLKMatrix4MultiplyVector4(inverseModelViewMatrix, GLKVector4Make(0, 0, 0, 1.f));
    GLKVector4 vCrMaxiMin = GLKMatrix4MultiplyVector4(inverseModelViewMatrix, GLKVector4Make(_screenSize.width, 0, 0, 1.f));
    GLKVector4 vCrMiniMax = GLKMatrix4MultiplyVector4(inverseModelViewMatrix, GLKVector4Make(0, _screenSize.height, 0, 1.f));
    // convert to complex plane
    CPPoint cOrigin = [self.fractal.complexPlane screenPointToComplexPlane:CGPointMake(vOrigin.x, vOrigin.y) screenSize:_screenSize];
    CPPoint crMaxiMin = [self.fractal.complexPlane screenPointToComplexPlane:CGPointMake(vCrMaxiMin.x, vCrMaxiMin.y) screenSize:_screenSize];
    CPPoint crMiniMax = [self.fractal.complexPlane screenPointToComplexPlane:CGPointMake(vCrMiniMax.x, vCrMiniMax.y) screenSize:_screenSize];
    return [ComplexPlane complexPlaneWithOrigin:cOrigin rMaxiMin:crMaxiMin rMiniMax:crMiniMax];
}

-(void)update {
    if (_pendingCompute) {
        _pendingCompute = NO;

        // update modelViewMatrix
        self.modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(_translateMatrix, GLKMatrix4Multiply(_scaleMatrix, _rotateMatrix)), self.modelViewMatrix);

        // compute new complex plane
        bool isInvertible;
        GLKMatrix4 inverseModelViewMatrix = GLKMatrix4Invert(self.modelViewMatrix, &isInvertible);
        if (!isInvertible) {
            [NSException raise:ExceptionLogicError format:@"modelViewMatrix not invertible"];
        }
        ComplexPlane* complexPlane = [self createComplexPlaneWithInverseModelViewMatrix:inverseModelViewMatrix];

        // reset matrices
        _translateMatrix = GLKMatrix4Identity;
        _rotateMatrix = GLKMatrix4Identity;
        _scaleMatrix = GLKMatrix4Identity;
        self.modelViewMatrix = GLKMatrix4Identity;

        // update fractal with new complex plane
        self.fractal.complexPlane = complexPlane;
    }
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
//    NSTimeInterval timeInterval = self.timeSinceLastUpdate;
//    if (timeInterval > (MinFrameTime + FrameTimeEpsilon)) {
//        _maxIterations -= _lastIterationDelta;
//        _lastIterationDelta = _maxIterations / 2;
//    } else if (timeInterval < (MinFrameTime - FrameTimeEpsilon)) {
//        _maxIterations += _lastIterationDelta;
//        _lastIterationDelta = _maxIterations / 2;
//    } else {
////        NSLog(@"_maxIterations = %d", _maxIterations);
//    }

    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    [self.fractal renderWithMaxIterations:_maxIterations];
}

-(void)initialiseMatrices {
    _translateMatrix = GLKMatrix4Translate(GLKMatrix4Identity, _initialPosition.x, _initialPosition.y, 0.0);
    _scaleMatrix = GLKMatrix4Scale(GLKMatrix4Identity, _initialScale, _initialScale, 1.0);
    _rotateMatrix = GLKMatrix4Rotate(GLKMatrix4Identity, _initialRotation, 0.0, 0.0, 1.0);
    self.modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(_translateMatrix, GLKMatrix4Multiply(_scaleMatrix, _rotateMatrix)), GLKMatrix4Identity);

    _scaleMatrix = GLKMatrix4Identity;
    _rotateMatrix = GLKMatrix4Identity;
    _translateMatrix = GLKMatrix4Identity;
}

-(void)translateWithTranslation:(CGPoint)translation veclocity:(CGPoint)velocity {
    _translateMatrix = GLKMatrix4Translate(_translateMatrix, translation.x, translation.y, 0.0);
    _translateVelocity = velocity;

    _pendingCompute = YES;
}

-(void)rotateWithCentre:(CGPoint)centre radians:(CGFloat)radians {
    _rotateMatrix = GLKMatrix4Translate(_rotateMatrix, centre.x, centre.y, 0.0);
    _rotateMatrix = GLKMatrix4Rotate(_rotateMatrix, radians, 0.0, 0.0, 1.0);
    _rotateMatrix = GLKMatrix4Translate(_rotateMatrix, -centre.x, -centre.y, 0.0);

    _pendingCompute = YES;
}

-(void)scaleWithCentre:(CGPoint)centre scale:(CGFloat)scale {
    _scaleMatrix = GLKMatrix4Translate(_scaleMatrix, centre.x, centre.y, 0.0);
    _scaleMatrix = GLKMatrix4Scale(_scaleMatrix, scale, scale, 1.0);
    _scaleMatrix = GLKMatrix4Translate(_scaleMatrix, -centre.x, -centre.y, 0.0);

    _pendingCompute = YES;
}

-(void)translateEndedWithTranslation:(CGPoint)translation veclocity:(CGPoint)velocity {
}

-(void)rotateEndedWithCentre:(CGPoint)centre radians:(CGFloat)radians {
}

-(void)scaleEndedWithCentre:(CGPoint)centre scale:(CGFloat)scale {
}

@end
