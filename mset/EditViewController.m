//
//  EditViewController.m
//  mset
//
//  Created by Jonathan Slater on 16/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@interface EditViewController()

@property (nonatomic, strong) RenderViewController* renderViewController;

@end

@implementation EditViewController

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
    CGPoint velocity = [recognizer velocityInView:self.renderViewController.view];
    if ([recognizer state] == UIGestureRecognizerStateBegan || [recognizer state] == UIGestureRecognizerStateChanged) {
        [self.renderViewController translateWithTranslation:translation veclocity:velocity];
        // no accumulation
        [recognizer setTranslation:CGPointZero inView:self.renderViewController.view];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.renderViewController translateEndedWithTranslation:translation veclocity:velocity];
    }
}

-(void)rotationGestureRecognizer:(UIRotationGestureRecognizer*)recognizer {
    CGPoint centre = [recognizer locationInView:self.renderViewController.view];
    if ([recognizer state] == UIGestureRecognizerStateBegan || [recognizer state] == UIGestureRecognizerStateChanged) {
        [self.renderViewController rotateWithCentre:centre radians:recognizer.rotation];
        // no accumulation
        recognizer.rotation = 0.f;
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.renderViewController rotateEndedWithCentre:centre radians:recognizer.rotation];
    }
}

-(void)pinchGestureRecognizer:(UIPinchGestureRecognizer*)recognizer {
    CGPoint centre = [recognizer locationInView:self.renderViewController.view];
    if ([recognizer state] == UIGestureRecognizerStateBegan || [recognizer state] == UIGestureRecognizerStateChanged) {
        [self.renderViewController scaleWithCentre:centre scale:recognizer.scale];
        // no accumulation
        recognizer.scale = 1.f;
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.renderViewController scaleEndedWithCentre:centre scale:recognizer.scale];
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
