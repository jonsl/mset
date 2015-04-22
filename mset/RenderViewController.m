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


@interface RenderViewController ()

@property (strong, nonatomic) EAGLContext* eaglContext;
@property (strong, nonatomic) GLKBaseEffect* effect;

@property (nonatomic, assign) GLKMatrix4 modelViewMatrix;

@property (nonatomic, strong) NSObject <Fractal>* fractal;

@property (nonatomic, strong) Quad* canvasQuad;
@property (nonatomic, assign) CGPoint canvasOffset;

@property (nonatomic, strong) ComplexPlane* complexPlane;

@end

@implementation RenderViewController {
    GLKMatrix4 _projectionMatrix;
    CGSize _screenSize;
    CGFloat _aspect;
    BOOL _requireCompute;

    GLKMatrix4 translatemt;
    GLKMatrix4 scalemt;
    GLKMatrix4 rotatemt;

    CGPoint initialPosition;
    CGFloat initialScale;
    CGFloat initialRotation;
}

-(void)viewDidLoad {
    [super viewDidLoad];

    self.eaglContext = [self createBestEAGLContext];
    if (self.eaglContext == nil) {
        [NSException raise:ExceptionLogicError format:@"invalid OpenGL ES Context"];
    }
    [EAGLContext setCurrentContext:self.eaglContext];

    self.effect = [[GLKBaseEffect alloc] init];

    initialPosition = CGPointMake(0, 0);
    initialScale = 1.f;
    initialRotation = 0.f;

    GLKView* view = (GLKView*) self.view;
    view.context = self.eaglContext;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.preferredFramesPerSecond = 60;

    [self setup];

    @try {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);

        _aspect = screenSize.width / screenSize.height;
        _screenSize = CGSizeMake(ScreenWidth, ScreenWidth / _aspect);
        _projectionMatrix = GLKMatrix4MakeOrtho(0, _screenSize.width, 0, _screenSize.height, 0.f, 1.f);

        Texture* canvasTexture = [Texture textureWithWidth:CanvasTextureSize height:CanvasTextureSize scale:1];
        self.canvasQuad = [Quad quadWithTexture:canvasTexture width:canvasTexture.width height:canvasTexture.height];

        self.complexPlane = [ComplexPlane complexPlaneWithCentre:-0.5 cI:0 rWidth:4.0 iHeight:4.0];

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

-(void)setCanvasOffset:(CGPoint)canvasOffset {
    float xOffset = MAX(-(self.canvasQuad.width - _screenSize.width), MIN(canvasOffset.x, 0));
    float yOffset = MAX(-(self.canvasQuad.height - _screenSize.height), MIN(canvasOffset.y, 0));
    _canvasOffset = CGPointMake(xOffset, yOffset);
    self.canvasQuad.position = _canvasOffset;
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

-(void)update {
    //this is done before every render update. It generates the modelViewMatrix from the temporary matrices
    self.modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(GLKMatrix4Multiply(rotatemt, translatemt), scalemt), self.modelViewMatrix);

    //And then set them back to identities
    translatemt = GLKMatrix4Identity;
    rotatemt = GLKMatrix4Identity;
    scalemt = GLKMatrix4Identity;

    //set the modelViewMatrix for the effect (this is assuming you are using OpenGL es 2.0, but it would be similar for previous versions
    self.effect.transform.modelviewMatrix = self.modelViewMatrix;
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
    Real xDelta = (_complexPlane.rMax - _complexPlane.rMin) / self.canvasQuad.width;
    Real yDelta = (_complexPlane.iMax - _complexPlane.iMin) / self.canvasQuad.height;
    CGPoint pt = CGPointMake(position.x - _canvasOffset.x, position.y - _canvasOffset.y);
    PPoint pp;
    pp.x = _complexPlane.rMin + (Real) pt.x * xDelta;
    pp.y = _complexPlane.iMin + (Real) pt.y * yDelta;
    return pp;
}

-(void)setup {

    //Creates the modelViewMatrix from the initial position, rotation and scale
    translatemt = GLKMatrix4Translate(GLKMatrix4Identity, initialPosition.x, initialPosition.y, 0.0);
    scalemt = GLKMatrix4Scale(GLKMatrix4Identity, initialScale, initialScale, 1.0);
    rotatemt = GLKMatrix4Rotate(GLKMatrix4Identity, initialRotation, 0.0, 0.0, 1.0);
    self.modelViewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(GLKMatrix4Multiply(translatemt, rotatemt), scalemt), GLKMatrix4Identity);

    //set these back to identities to take further modifications (they'll update the modelViewMatrix)
    scalemt = GLKMatrix4Identity;
    rotatemt = GLKMatrix4Identity;
    translatemt = GLKMatrix4Identity;


    //rest of the OpenGL setup
//    [self setupOpengGL];

}

-(void)translate:(CGPoint)location {
    translatemt = GLKMatrix4Translate(translatemt, location.x, -location.y, 0.0);
}

-(void)rotate:(CGPoint)location radians:(CGFloat)radians {
    rotatemt = GLKMatrix4Translate(GLKMatrix4Identity, location.x, -location.y, 0.0);
    rotatemt = GLKMatrix4Rotate(rotatemt, -radians, 0.0, 0.0, 1.0);
    rotatemt = GLKMatrix4Translate(rotatemt, -location.x, location.y, 0.0);
}

-(void)scale:(CGPoint)location scale:(CGFloat)scale {
    scalemt = GLKMatrix4Translate(GLKMatrix4Identity, location.x, -location.y, 0.0);
    scalemt = GLKMatrix4Scale(scalemt, scale, scale, 1.0);
    scalemt = GLKMatrix4Translate(scalemt, -location.x, location.y, 0.0);
}

@end
