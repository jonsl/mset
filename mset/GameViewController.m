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

-(void)update {
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    if (_requireCompute) {
        double centerX = -0.5;
        double centerY = 0;
        double sizeX = 4;
        NSInteger maxIterations = 100;

        [self.fractal compute:self.renderer.texture.imageData
                        width:self.renderer.texture.width
                       height:self.renderer.texture.height
                         xMin:centerX - (sizeX / 2)
                         xMax:centerX + (sizeX / 2)
                         yMin:centerY - (sizeX / 2)
                         yMax:centerY + (sizeX / 2)
                 escapeRadius:2
                maxIterations:maxIterations
                   updateDraw:^() {
                       [self.renderer.texture replace];
                   }];
        _requireCompute = NO;
    }
    [self.renderer render];
}

@end
