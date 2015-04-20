//
//  GameViewController.m
//  mset
//
//  Created by Jonathan Slater on 16/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


float const ScreenWidth = 1024.f;
float const CanvasTextureSize = 1024.f;
NSInteger const MaxIterations = 1000;

@interface GameViewController ()

@property (strong, nonatomic) EAGLContext* eaglContext;
@property (strong, nonatomic) CIContext* ciContext;
@property (nonatomic, strong) NSObject<Fractal>* fractal;

@property (nonatomic, strong) Quad* canvasQuad;
@property (nonatomic, assign) CGPoint canvasOffset;
@property (nonatomic, strong) Quad* selectionQuad;

@property (nonatomic, assign) CGPoint dragStart;
@property (nonatomic, assign) CGPoint dragCanvasOffset;

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

    [self.view setMultipleTouchEnabled:YES];

    [self setupGL];

    @try {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);

        float aspect = screenSize.width / screenSize.height;
        _screenSize = CGSizeMake(ScreenWidth, ScreenWidth / aspect);
        _projectionMatrix = GLKMatrix4MakeOrtho(0, _screenSize.width, 0, _screenSize.height, 0.f, 1.f);

        Texture* canvasTexture = [Texture textureWithWidth:CanvasTextureSize height:CanvasTextureSize scale:1];
        self.canvasQuad = [Quad quadWithTexture:canvasTexture width:canvasTexture.width height:canvasTexture.height];

        CGPoint delta = CGPointMake(self.canvasQuad.width - _screenSize.width, self.canvasQuad.height - _screenSize.height);
        self.canvasOffset = CGPointMake(-delta.x / 2, -delta.y / 2);
//        self.screenPosition = CGPointMake(0, -300);

        self.selectionQuad = [Quad quadWithColour:0xff width:100 height:100];
        self.selectionQuad.position = CGPointMake(0, 0);
        self.selectionQuad.visible = NO;


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
    self.fractal.fractalDescriptor = self.fractalDescriptor;
//    DefaultColourMap* defaultColourTable = [[DefaultColourMap alloc] initWithSize:4096];
    BernsteinPolynomialColourMap* newColourMap = [[BernsteinPolynomialColourMap alloc] initWithSize:4096];
    [self.fractal compute:self.canvasQuad.texture.imageData
                    width:self.canvasQuad.texture.width
                   height:self.canvasQuad.texture.height
//              colourTable:defaultColourTable
              colourTable:newColourMap
           executionUnits:[Configuration sharedConfiguration].executionUnits
               updateDraw:
                       ^() {
                           [self.canvasQuad updateImage];
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

    [self.canvasQuad renderWithMvpMatrix:_projectionMatrix alpha:1.f];
    [self.selectionQuad renderWithMvpMatrix:_projectionMatrix alpha:0.5f];
}

-(CGPoint)touchToCanvas:(CGPoint)touch {
    return CGPointMake(touch.x, _screenSize.height - touch.y);
}

-(PPoint)canvasToComplexPlane:(CGPoint)position {
    Real xDelta = (_fractalDescriptor.xMax - _fractalDescriptor.xMin) / self.canvasQuad.width;
    Real yDelta = (_fractalDescriptor.yMax - _fractalDescriptor.yMin) / self.canvasQuad.height;
    CGPoint pt = CGPointMake(position.x - _canvasOffset.x, position.y - _canvasOffset.y);
    PPoint pp;
    pp.x = _fractalDescriptor.xMin + (Real) pt.x * xDelta;
    pp.y = _fractalDescriptor.yMin + (Real) pt.y * yDelta;
    return pp;
}

#pragma mark UIResponder

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    NSSet* touchesForView = [event touchesForView:self.view];
    NSArray* allTouchesForView = [touchesForView allObjects];
    _lastTouchCount = _touchCount;
    _touchCount = [allTouchesForView count];
    if (_touchCount == 1) {
        CGPoint pt = [allTouchesForView[0] locationInView:self.view];
        [self beginDragWithTouch:pt];
    } else if (_touchCount == 2) {
        CGPoint pt1 = [allTouchesForView[0] locationInView:self.view];
        CGPoint pt2 = [allTouchesForView[1] locationInView:self.view];
        [self showSelectionAreaWithTouches:pt1 second:pt2];
    }
}

-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    NSSet* touchesForView = [event touchesForView:self.view];
    NSArray* allTouchesForView = [touchesForView allObjects];
    _lastTouchCount = _touchCount;
    _touchCount = [allTouchesForView count];
    if (_touchCount == 1) {
        CGPoint pt = [allTouchesForView[0] locationInView:self.view];
        if (_lastTouchCount == 2) {
            [self beginDragWithTouch:pt];
        }
        [self dragWithTouch:pt];
    } else if (_touchCount == 2) {
        CGPoint pt1 = [allTouchesForView[0] locationInView:self.view];
        CGPoint pt2 = [allTouchesForView[1] locationInView:self.view];
        [self showSelectionAreaWithTouches:pt1 second:pt2];
    }
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    NSSet* touchesForView = [event touchesForView:self.view];
    NSArray* allTouchesForView = [touchesForView allObjects];
    _lastTouchCount = _touchCount;
    _touchCount = [allTouchesForView count];
    if (_touchCount == 1) {
        CGPoint pt = [allTouchesForView[0] locationInView:self.view];
        [self endDragWithTouch:pt];
    }
    if (self.selectionQuad.visible) {
        [self computeSelectionArea];
        self.selectionQuad.visible = NO;
    }
}

-(void)beginDragWithTouch:(CGPoint)touch {
    _dragStart = [self touchToCanvas:touch];
    _dragCanvasOffset = _canvasOffset;
}

-(void)dragWithTouch:(CGPoint)touch {
    CGPoint pt = [self touchToCanvas:touch];
    self.canvasOffset = CGPointMake(_dragCanvasOffset.x - _dragStart.x + pt.x, _dragCanvasOffset.y - _dragStart.y + pt.y);
}

-(void)endDragWithTouch:(CGPoint)touch {
}

-(void)showSelectionAreaWithTouches:(CGPoint)touch1 second:(CGPoint)touch2 {
    CGPoint pt1 = [self touchToCanvas:touch1];
    CGPoint pt2 = [self touchToCanvas:touch2];
    CGPoint mid = CGPointMake(pt1.x + (pt2.x - pt1.x) / 2, pt1.y + (pt2.y - pt1.y) / 2);
    CGFloat size = MAX(fabs(pt2.x - pt1.x), fabs(pt2.y - pt1.y));
    CGPoint bl = CGPointMake(mid.x - size / 2, mid.y - size / 2);

    self.selectionQuad.width = size;
    self.selectionQuad.height = size;
    self.selectionQuad.position = bl;
    self.selectionQuad.visible = YES;
}

-(void)computeSelectionArea {
    float xMin = self.selectionQuad.position.x;
    float xMax = self.selectionQuad.position.x + self.selectionQuad.width;
    float yMin = self.selectionQuad.position.y;
    float yMax = self.selectionQuad.position.y + self.selectionQuad.height;

    CGPoint bl = CGPointMake(xMin, yMin);
    CGPoint tr = CGPointMake(xMax, yMax);

    PPoint a = [self canvasToComplexPlane:bl];
    PPoint b = [self canvasToComplexPlane:tr];

    self.fractalDescriptor = [FractalDescriptor fractalDescriptorWithXMin:a.x
                                                                     xMax:b.x
                                                                     yMin:a.y
                                                                     yMax:b.y
                                                             escapeRadius:2
                                                            maxIterations:MaxIterations];

    _requireCompute = YES;
}

@end
