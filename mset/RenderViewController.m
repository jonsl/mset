//
//  RenderViewController.m
//  mset
//
//  Created by Jonathan Slater on 22/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

static float const ScreenWidth = 1024.f;
static float const CanvasTextureSize = 1024.f;
static NSInteger const MaxIterations = 1000;
static Real InitialRealWidth = 4;


@interface RenderViewController ()

@property (strong, nonatomic) EAGLContext* eaglContext;
@property (nonatomic, assign) GLKMatrix4 modelViewMatrix;
@property (nonatomic, strong) NSObject<Fractal>* fractal;
@property (nonatomic, strong) Quad* canvasQuad;
@property (nonatomic, strong) ComplexPlane* complexPlane;

@end

@implementation RenderViewController {
    GLKMatrix4 _projectionMatrix;
    CGSize _screenSize;
    CGFloat _aspect;
    BOOL _requireCompute;

    GLKMatrix4 _translateCanvas;
    GLKMatrix4 _scaleCanvas;
    GLKMatrix4 _rotateCanvas;

    GLKMatrix4 _translateCP;
    GLKMatrix4 _scaleCP;
    GLKMatrix4 _rotateCP;

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

        self.complexPlane = [ComplexPlane complexPlaneWithCentre:-0.5 cI:0 rWidth:InitialRealWidth iHeight:InitialRealWidth / _aspect];

        _requireCompute = YES;

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
    //    NSLog(@"recomputing with xMin: %@, xMax: %@, yMin: %@, yMax: %@", @(_fractalDescriptor.xMin), @(_fractalDescriptor.xMax), @(_fractalDescriptor.yMin), @(_fractalDescriptor.yMax));
    self.fractal.complexPlane = self.complexPlane;
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

-(void)transformComplexPlane {
    bool isInvertible = false;
    GLKMatrix4 inverseModelViewMatrix = GLKMatrix4Invert(self.modelViewMatrix, &isInvertible);
    [self.complexPlane transform:inverseModelViewMatrix];
}

-(void)update {
    self.modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(GLKMatrix4Multiply(_scaleCanvas, _rotateCanvas), _translateCanvas), self.modelViewMatrix);

    [self transformComplexPlane];

    _translateCanvas = GLKMatrix4Identity;
    _rotateCanvas = GLKMatrix4Identity;
    _scaleCanvas = GLKMatrix4Identity;

    if (_requireCompute) {
        [self compute];
        _requireCompute = NO;
    }
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(_projectionMatrix, self.modelViewMatrix);
    [self.canvasQuad renderWithMvpMatrix:mvpMatrix alpha:1.f];
}

-(CGPoint)touchToCanvas:(CGPoint)touch {
    return CGPointMake(touch.x, _screenSize.height - touch.y);
}

-(PPoint)canvasPointToComplexPlane:(CGPoint)position {
    Real xDelta = (_complexPlane.rMax - _complexPlane.rMin) / _screenSize.width;
    Real yDelta = (_complexPlane.iMax - _complexPlane.iMin) / _screenSize.height;
    PPoint pp;
    pp.x = _complexPlane.rMin + (Real) position.x * xDelta;
    pp.y = _complexPlane.iMin + (Real) position.y * yDelta;
    return pp;
}

-(void)initialiseMatrices {
    _translateCanvas = GLKMatrix4Translate(GLKMatrix4Identity, _initialPosition.x, _initialPosition.y, 0.0);
    _scaleCanvas = GLKMatrix4Scale(GLKMatrix4Identity, _initialScale, _initialScale, 1.0);
    _rotateCanvas = GLKMatrix4Rotate(GLKMatrix4Identity, _initialRotation, 0.0, 0.0, 1.0);
    self.modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(GLKMatrix4Multiply(_scaleCanvas, _rotateCanvas), _translateCanvas), GLKMatrix4Identity);

    _scaleCanvas = GLKMatrix4Identity;
    _rotateCanvas = GLKMatrix4Identity;
    _translateCanvas = GLKMatrix4Identity;
}

-(void)translate:(CGPoint)location {
    _translateCanvas = GLKMatrix4Translate(_translateCanvas, location.x, -location.y, 0.0);
}

-(void)rotate:(CGPoint)location radians:(CGFloat)radians {
    CGPoint pt = [self touchToCanvas:location];
    _rotateCanvas = GLKMatrix4Translate(GLKMatrix4Identity, pt.x, pt.y, 0.0);
    _rotateCanvas = GLKMatrix4Rotate(_rotateCanvas, -radians * 2.f, 0.0, 0.0, 1.0);
    _rotateCanvas = GLKMatrix4Translate(_rotateCanvas, -pt.x, -pt.y, 0.0);
}

-(void)scale:(CGPoint)location scale:(CGFloat)scale {
    CGPoint pt = [self touchToCanvas:location];
    _scaleCanvas = GLKMatrix4Translate(GLKMatrix4Identity, pt.x, pt.y, 0.0);
    _scaleCanvas = GLKMatrix4Scale(_scaleCanvas, scale, scale, 1.0);
    _scaleCanvas = GLKMatrix4Translate(_scaleCanvas, -pt.x, -pt.y, 0.0);
}

@end
