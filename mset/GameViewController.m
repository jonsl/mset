//
//  GameViewController.m
//  mset
//
//  Created by Jonathan Slater on 16/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@interface GameViewController ()

@property (strong, nonatomic) EAGLContext* eaglContext;
@property (strong, nonatomic) CIContext* ciContext;
@property (nonatomic, strong) NSObject<Fractal>* fractal;
@property (nonatomic, strong) Quad* screenQuad;

@end

@implementation GameViewController {
    BOOL _requireCompute;
    CGRect _rectangle;
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
    self.multitouchEnabled = true;

    [self setupGL];

    @try {
//        CGRect screenBounds = [[UIScreen mainScreen] bounds];
//        CGFloat screenScale = [[UIScreen mainScreen] scale];
//        CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
        CGSize screenSize = CGSizeMake(1024, 768);
        self.screenQuad = [Quad quadWithWidth:screenSize.width height:screenSize.height];
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

    // Dispose of any resources that can be recreated.
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
        [self.fractal compute:self.screenQuad.texture.imageData
                        width:self.screenQuad.texture.width
                       height:self.screenQuad.texture.height
               executionUnits:[Configuration sharedConfiguration].executionUnits
                   updateDraw:^() {
                       [self.screenQuad updateImage];
                   }];
        _requireCompute = NO;
    }
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    [self.screenQuad renderWithAlpha:1.f];
}

-(void)setMultitouchEnabled:(BOOL)multitouchEnabled {
    self.view.multipleTouchEnabled = multitouchEnabled;
}

-(BOOL)multitouchEnabled {
    return self.view.multipleTouchEnabled;
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    for (UITouch* touch in touches) {
        CGPoint location = [touch locationInView:self.view];
        _rectangle.origin = location;
    }
}

-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    for (UITouch* touch in touches) {
        CGPoint location = [touch locationInView:self.view];
        _rectangle.size = CGSizeMake(location.x - _rectangle.origin.x, location.y - _rectangle.origin.y);
    }
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    for (UITouch* __unused touch in touches) {
    }
}

-(void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
}

@end
