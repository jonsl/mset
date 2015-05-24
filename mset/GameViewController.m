//
//  GameViewController.m
//  mset
//
//  Created by Jonathan Slater on 16/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@interface GameViewController()

@property (nonatomic, strong) RenderViewController* renderViewController;

@end

@implementation GameViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    self.renderViewController = [[RenderViewController alloc] initWithNibName:@"RenderViewController" bundle:nil];
    [self addChildViewController:self.renderViewController];
    self.renderViewController.view.frame = self.view.frame;
    [self.view addSubview:self.renderViewController.view];
    [self.renderViewController didMoveToParentViewController:self];

    [self addGestureRecognizers];
}

-(void)dealloc {
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)addGestureRecognizers {
    [self removeGestureRecognizers];

    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    [self.renderViewController.view addGestureRecognizer:panGesture];
    panGesture.delegate = self;

    UIRotationGestureRecognizer* rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGestureRecognizer:)];
    [self.renderViewController.view addGestureRecognizer:rotationGesture];
    rotationGesture.delegate = self;

    UIPinchGestureRecognizer* pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizer:)];
    [self.renderViewController.view addGestureRecognizer:pinchGesture];
    pinchGesture.delegate = self;
}

-(void)removeGestureRecognizers {
    for (UIGestureRecognizer* gestureRecognizer in self.renderViewController.view.gestureRecognizers) {
        [self.renderViewController.view removeGestureRecognizer:gestureRecognizer];
    }
}

-(void)panGestureRecognizer:(UIPanGestureRecognizer*)recognizer {
    CGPoint translation = [recognizer translationInView:self.renderViewController.view];
    [self.renderViewController translate:translation];
    // no accumulation
    [recognizer setTranslation:CGPointZero inView:self.renderViewController.view];
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.renderViewController translateEnded];
    }
}

-(void)rotationGestureRecognizer:(UIRotationGestureRecognizer*)recognizer {
    CGPoint locationInView = [recognizer locationInView:self.renderViewController.view];
    if ([recognizer state] == UIGestureRecognizerStateBegan || [recognizer state] == UIGestureRecognizerStateChanged) {
        [self.renderViewController rotate:locationInView radians:recognizer.rotation];
        // no accumulation
        recognizer.rotation = 0.f;
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.renderViewController rotateEnded];
    }
}

-(void)pinchGestureRecognizer:(UIPinchGestureRecognizer*)recognizer {
    CGPoint locationInView = [recognizer locationInView:self.renderViewController.view];
    if ([recognizer state] == UIGestureRecognizerStateBegan || [recognizer state] == UIGestureRecognizerStateChanged) {
        [self.renderViewController scale:locationInView scale:recognizer.scale];
        // no accumulation
        recognizer.scale = 1.f;
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.renderViewController scaleEnded];
    }
}

// following allows gestures recognizers to happen simultaneously
-(BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    if (gestureRecognizer.view != otherGestureRecognizer.view) {
        return NO;
    }
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}

@end
