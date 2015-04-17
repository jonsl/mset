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
@property (nonatomic, strong) SetRenderer* setRenderer;

@end

@implementation GameViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }

    GLKView* view = (GLKView*) self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [self setupGL];

    @try {
        self.setRenderer = [SetRenderer setRendererWithWidth:1024 height:768];
    }
    @catch (NSException* ex) {
        NSLog(@"exception: '%@', reason: '%@'", ex.name, ex.reason);
    }
    @finally {

    }
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

    [self.setRenderer render];

}

@end
