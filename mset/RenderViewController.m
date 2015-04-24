//
//  RenderViewController.m
//  mset
//
//  Created by Jonathan Slater on 22/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#import "Util.h"

static float const ScreenWidth = 1024.f;
static float const CanvasTextureSize = 1024.f;
static NSInteger const MaxIterations = 1000;
static Real InitialRealCentre = -0.5;
static Real InitialRealWidth = 4;


@interface RenderViewController ()

@property (strong, nonatomic) EAGLContext* eaglContext;
@property (nonatomic, assign) GLKMatrix4 modelViewMatrix;
@property (nonatomic, assign) CPPoint cOrigin;
@property (nonatomic, assign) CPPoint crMaxiMin;
@property (nonatomic, assign) CPPoint crMiniMax;
@property (nonatomic, strong) NSObject<Fractal>* fractal;
@property (nonatomic, strong) Quad* canvasQuad;
@property (nonatomic, strong) ComplexPlane* complexPlane;

@end

@implementation RenderViewController {
    GLKMatrix4 _projectionMatrix;
    CGSize _screenSize;
    CGFloat _aspect;
    BOOL _recomputing;
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

    GLKView* view = (GLKView*) self.view;
    view.context = self.eaglContext;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.preferredFramesPerSecond = 60;

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

        Texture* canvasTexture = [Texture textureWithWidth:CanvasTextureSize height:CanvasTextureSize scale:1];
        self.canvasQuad = [Quad quadWithTexture:canvasTexture width:canvasTexture.width height:canvasTexture.height];

        Real rHalfExtent = 0.5 * InitialRealWidth;
        Real iHalfExtent = 0.5 * InitialRealWidth / _aspect;
        _cOrigin.r = InitialRealCentre - rHalfExtent;
        _cOrigin.i = -iHalfExtent;
        _crMaxiMin.r = _cOrigin.r + InitialRealWidth;
        _crMaxiMin.i = -iHalfExtent;
        _crMiniMax.r = _cOrigin.r;
        _crMiniMax.i = +iHalfExtent;

        self.complexPlane = [ComplexPlane complexPlaneWithOrigin:_cOrigin rMaxiMin:_crMaxiMin rMiniMax:_crMiniMax];

        _recomputing = NO;
        _pendingCompute = YES;

        self.fractal = [MandelbrotSet mandelbrotSet];
    }
    @catch (NSException* ex) {
        NSLog(@"exception: '%@', reason: '%@'", ex.name, ex.reason);
    }
    @finally {

    }
}

-(void)didMoveToParentViewController:(UIViewController*)parent {

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
    NSLog(@"recomputing with complex plane origin(%lf,%lf), rMiniMax(%lf,%lf), rMiniMax(%lf,%lf)", _complexPlane.origin.r, _complexPlane.origin.i,
            _complexPlane.rMaxiMin.r, _complexPlane.rMaxiMin.i, _complexPlane.rMiniMax.r, _complexPlane.rMiniMax.i);
    self.complexPlane = [ComplexPlane complexPlaneWithOrigin:_cOrigin rMaxiMin:_crMaxiMin rMiniMax:_crMiniMax];
    self.fractal.complexPlane = self.complexPlane;
    self.modelViewMatrix = GLKMatrix4Identity;
    //    DefaultColourMap* defaultColourTable = [[DefaultColourMap alloc] initWithSize:4096];
    PolynomialColourMap* newColourMap = [[PolynomialColourMap alloc] initWithSize:4096];
    [self.fractal compute:self.canvasQuad.texture.imageData
                    width:_screenSize.width
                   height:_screenSize.height
             escapeRadius:(NSInteger) 2
            maxIterations:(NSUInteger) MaxIterations
            //              colourMap:defaultColourTable
                colourMap:newColourMap
           executionUnits:[Configuration sharedConfiguration].executionUnits
               updateDraw:
                       ^() {
                           [self.canvasQuad updateImage];
                       }];
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

    _cOrigin = cOrigin;
    NSLog(@"pp = (%lf,%lf)", _cOrigin.r, _cOrigin.i);
    _crMaxiMin = crMaxiMin;
    _crMiniMax = crMiniMax;
}

-(void)update {
    self.modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(GLKMatrix4Multiply(_scaleMatrix, _rotateMatrix), _translateMatrix), self.modelViewMatrix);
    _translateMatrix = GLKMatrix4Identity;
    _rotateMatrix = GLKMatrix4Identity;
    _scaleMatrix = GLKMatrix4Identity;

    if (!_recomputing && _pendingCompute) {
        _recomputing = YES;
        [self screenToComplexPlane];
        [self compute];
        _recomputing = NO;

        _pendingCompute = NO;
    }
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    glClearColor(0.f, 0.f, 0.f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(_projectionMatrix, self.modelViewMatrix);
    [self.canvasQuad renderWithMvpMatrix:mvpMatrix alpha:1.f];
}

-(CGPoint)touchToCanvas:(CGPoint)touch {
    return CGPointMake(touch.x, _screenSize.height - touch.y);
}

Real cpLength(CPPoint p1, CPPoint p2) {
    return sqrt((p2.r - p1.r) * (p2.r - p1.r) + (p2.i - p1.i) * (p2.i - p1.i));
}

-(CPPoint)canvasPointToComplexPlane:(CGPoint)position {
    Real xLen = (Real) position.x / _screenSize.width;
    Real yLen = (Real) position.y / _screenSize.height;
    CPPoint pp;
    pp.r = _cOrigin.r + xLen * (_crMaxiMin.r - _cOrigin.r) + yLen * (_crMiniMax.r - _cOrigin.r);
    pp.i = _cOrigin.i + yLen * (_crMiniMax.i - _cOrigin.i) + xLen * (_crMaxiMin.i - _cOrigin.i);
    return pp;
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
    if (_pendingCompute) {
        return ;
    }
    _translateMatrix = GLKMatrix4Translate(_translateMatrix, location.x, -location.y, 0.0);
}

-(void)rotate:(CGPoint)location radians:(CGFloat)radians {
    if (_pendingCompute) {
        return ;
    }
    CGPoint pt = [self touchToCanvas:location];
    _rotateMatrix = GLKMatrix4Translate(GLKMatrix4Identity, pt.x, pt.y, 0.0);
    _rotateMatrix = GLKMatrix4Rotate(_rotateMatrix, -radians * 2.f, 0.0, 0.0, 1.0);
    _rotateMatrix = GLKMatrix4Translate(_rotateMatrix, -pt.x, -pt.y, 0.0);
}

-(void)scale:(CGPoint)location scale:(CGFloat)scale {
    if (_pendingCompute) {
        return ;
    }
    CGPoint pt = [self touchToCanvas:location];
    _scaleMatrix = GLKMatrix4Translate(GLKMatrix4Identity, pt.x, pt.y, 0.0);
    _scaleMatrix = GLKMatrix4Scale(_scaleMatrix, scale, scale, 1.0);
    _scaleMatrix = GLKMatrix4Translate(_scaleMatrix, -pt.x, -pt.y, 0.0);
}

-(void)translateEnded {
    _pendingCompute = YES;
}

-(void)rotateEnded {
    _pendingCompute = YES;
}

-(void)scaleEnded {
    _pendingCompute = YES;
}

@end
