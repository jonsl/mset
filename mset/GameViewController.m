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
@property (strong, nonatomic) GLKBaseEffect* effect;
@property (nonatomic, strong) RendererState* rendererState;
@property (nonatomic, strong) Texture* texture;

-(void)setupGL;

-(void)tearDownGL;

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
        // test RendererState
        self.rendererState = [RendererState rendererState];

        self.texture = [Texture textureWithWidth:20 height:20 scale:1];
        NSAssert(self.texture != nil, @"invalid test texture");
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

        [self tearDownGL];

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

    self.effect = nil;

}

#pragma mark - GLKView and GLKViewController delegate methods

-(void)update {
}

-(void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    [self.texture setPixel:0 rgba:COLOUR_RGBA(0x10, 0x20, 0x30, 0x40)];

//    self.texture.imageData[0] = 0xff;
//    self.texture.imageData[1] = 0xff;
//    self.texture.imageData[2] = 0xff;
//    self.texture.imageData[3] = 0xff;

    [self.texture replace];

    self.rendererState.mvpMatrix = GLKMatrix4Identity;
    self.rendererState.texture = self.texture;
    [self.rendererState prepareState];

//    [self renderTextures];

}

@end
