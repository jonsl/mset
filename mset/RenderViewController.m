//
//  RenderViewController.m
//  mset
//
//  Created by Jonathan Slater on 22/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#import "matrix4.h"

static float const kScreenWidth = 1024.f;
static Real kInitialRealCentre = -0.5;
static Real kInitialRealWidth = 4;
static NSInteger const DEFAULT_MAX_ITERATIONS = 256;
static NSInteger const FPS_FRAME_UPDATE_COUNT = 50;

//static Real MinFrameTime = 1.0 / 20.0;
//static Real FrameTimeEpsilon = 1.0 / 20.0 - 1.0 / 22.0;

@interface RenderViewController()

@property (nonatomic, strong) EditViewController* editViewController;
@property (nonatomic, strong) EAGLContext* eaglContext;
@property (nonatomic, assign) Matrix4 modelMatrix;
@property (nonatomic, strong) NSObject<Fractal>* fractal;

@end

@implementation RenderViewController {
    CGSize _screenSize;
    CGFloat _aspect;

    NSInteger _frameCounter;
    NSDate* _frameStartTime;

    BOOL _pendingCompute;

    GLKMatrix4 _projectionMatrix;

    Matrix4 _translateMatrix;
    CGPoint _translateVelocity;
    Matrix4 _scaleMatrix;
    Matrix4 _rotateMatrix;

    double _radius;

    Point2 _initialPosition;
    double _initialScale;
    double _initialRotation;

    GLint _maxIterations;
    NSInteger _lastIterationDelta;
}

-(void)viewDidLoad {
    [super viewDidLoad];

    self.eaglContext = [self createBestEAGLContext];
    NSAssert(self.eaglContext != nil, @"invalid OpenGL ES Context");
    [EAGLContext setCurrentContext:self.eaglContext];

    GLKView* view = (GLKView*) self.view;
    view.context = self.eaglContext;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.preferredFramesPerSecond = 30;

    _initialPosition = point2Make(0, 0);
    _initialScale = 1.;
    _initialRotation = 0.;

    [self initialiseMatrices];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);

    _aspect = screenSize.width / screenSize.height;
    _screenSize = CGSizeMake(kScreenWidth, kScreenWidth / _aspect);

    _projectionMatrix = GLKMatrix4MakeOrtho(0.f, _screenSize.width, 0.f, _screenSize.height, 0.f, 1.f);

    _aspect = screenSize.width / screenSize.height;
    _screenSize = CGSizeMake(kScreenWidth, kScreenWidth / _aspect);

    _maxIterations = DEFAULT_MAX_ITERATIONS;
    _lastIterationDelta = DEFAULT_MAX_ITERATIONS >> 1;

    self.fractal = [MandelbrotSet mandelbrotSetWithWidth:_screenSize.width height:_screenSize.height];

    [self initialiseComplexPlane];

    _pendingCompute = YES;

    _frameStartTime = [NSDate date];
}

-(void)initialiseComplexPlane {
    Real rHalfExtent = 0.5 * kInitialRealWidth;
    Real iHalfExtent = 0.5 * kInitialRealWidth / _aspect;
    Point2 cOrigin, rMaxiMin, rMiniMax;
    cOrigin.r = kInitialRealCentre - rHalfExtent;
    cOrigin.i = -iHalfExtent;
    rMaxiMin.r = cOrigin.r + kInitialRealWidth;
    rMaxiMin.i = -iHalfExtent;
    rMiniMax.r = cOrigin.r;
    rMiniMax.i = +iHalfExtent;
    self.fractal.complexPlane = [ComplexPlane complexPlaneWithOrigin:cOrigin rMaxiMin:rMaxiMin rMiniMax:rMiniMax];
}

-(void)didMoveToParentViewController:(UIViewController*)parent {
    if ([parent isKindOfClass:[EditViewController class]]) {
        self.editViewController = (EditViewController*) parent;
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

-(ComplexPlane*)createComplexPlaneWithInverseModelViewMatrix:(Matrix4)inverseModelMatrix {
    // un-transform full size screen coordinates to get new screen
    Vector4 vOrigin = matrix4MultiplyVector4(inverseModelMatrix, vector4Make(0, 0, 0, 1.));
    Vector4 vCrMaxiMin = matrix4MultiplyVector4(inverseModelMatrix, vector4Make(_screenSize.width, 0, 0, 1.));
    Vector4 vCrMiniMax = matrix4MultiplyVector4(inverseModelMatrix, vector4Make(0, _screenSize.height, 0, 1.));
    // convert to complex plane
    Point2 cOrigin = [self.fractal.complexPlane screenPointToComplexPlane:point2Make(vOrigin.x, vOrigin.y) screenSize:_screenSize];
    Point2 crMaxiMin = [self.fractal.complexPlane screenPointToComplexPlane:point2Make(vCrMaxiMin.x, vCrMaxiMin.y) screenSize:_screenSize];
    Point2 crMiniMax = [self.fractal.complexPlane screenPointToComplexPlane:point2Make(vCrMiniMax.x, vCrMiniMax.y) screenSize:_screenSize];
    return [ComplexPlane complexPlaneWithOrigin:cOrigin rMaxiMin:crMaxiMin rMiniMax:crMiniMax];
}

-(void)update {
    if (_pendingCompute) {
        _pendingCompute = NO;

        // update modelViewMatrix
        self.modelMatrix = matrix4Multiply(matrix4Multiply(_translateMatrix, matrix4Multiply(_scaleMatrix, _rotateMatrix)), self.modelMatrix);

        // compute new complex plane
        bool isInvertible;
        Matrix4 inverseModelMatrix = matrix4Invert(self.modelMatrix, &isInvertible);
        NSAssert(isInvertible, @"modelViewMatrix not invertible");
        ComplexPlane* complexPlane = [self createComplexPlaneWithInverseModelViewMatrix:inverseModelMatrix];

        // reset matrices
        _translateMatrix = g_matrix4Identity;
        _rotateMatrix = g_matrix4Identity;
        _scaleMatrix = g_matrix4Identity;
        self.modelMatrix = g_matrix4Identity;

        // update fractal with new complex plane
        self.fractal.complexPlane = complexPlane;
    }
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    [self.fractal renderWithMvpMatrix:_projectionMatrix
                       fragmentShader:@"singleFloatMandel"
                           renderMode:RenderModeSinglePrecision
                           iterations:_maxIterations
                               radius:_radius
                         frameCounter:_frameCounter];

    // update fps
    if (!(++_frameCounter % FPS_FRAME_UPDATE_COUNT)) {
        NSTimeInterval timeInterval = [_frameStartTime timeIntervalSinceNow];
        double fps = -FPS_FRAME_UPDATE_COUNT / timeInterval;
        NSLog(@"fps: %lf", fps);
        _frameStartTime = [NSDate date];
    }
}

-(void)initialiseMatrices {
    _translateMatrix = matrix4Translate(g_matrix4Identity, _initialPosition.x, _initialPosition.y, 0.0);
    _scaleMatrix = matrix4Scale(g_matrix4Identity, _initialScale, _initialScale, 1.0);
    _rotateMatrix = matrix4Rotate(g_matrix4Identity, _initialRotation, 0.0, 0.0, 1.0);
    self.modelMatrix = matrix4Multiply(matrix4Multiply(_translateMatrix, matrix4Multiply(_scaleMatrix, _rotateMatrix)), g_matrix4Identity);

    _scaleMatrix = g_matrix4Identity;
    _rotateMatrix = g_matrix4Identity;
    _translateMatrix = g_matrix4Identity;
}

-(void)translateWithTranslation:(CGPoint)translation veclocity:(CGPoint)velocity {
    _translateMatrix = matrix4Translate(_translateMatrix, translation.x, translation.y, 0.0);
    _translateVelocity = velocity;

    _pendingCompute = YES;
}

-(void)rotateWithCentre:(CGPoint)centre radians:(CGFloat)radians {
    _rotateMatrix = matrix4Translate(_rotateMatrix, centre.x, centre.y, 0.0);
    _rotateMatrix = matrix4Rotate(_rotateMatrix, radians, 0.0, 0.0, 1.0);
    _rotateMatrix = matrix4Translate(_rotateMatrix, -centre.x, -centre.y, 0.0);

    _pendingCompute = YES;
}

-(void)scaleWithCentre:(CGPoint)centre scale:(CGFloat)scale {
    _scaleMatrix = matrix4Translate(_scaleMatrix, centre.x, centre.y, 0.0);
    _scaleMatrix = matrix4Scale(_scaleMatrix, scale, scale, 1.0);
    _scaleMatrix = matrix4Translate(_scaleMatrix, -centre.x, -centre.y, 0.0);

    _pendingCompute = YES;
}

-(void)translateEndedWithTranslation:(CGPoint)translation veclocity:(CGPoint)velocity {
}

-(void)rotateEndedWithCentre:(CGPoint)centre radians:(CGFloat)radians {
}

-(void)scaleEndedWithCentre:(CGPoint)centre scale:(CGFloat)scale {
}

@end
