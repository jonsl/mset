//
//  GameViewController.m
//  mset
//
//  Created by Jonathan Slater on 16/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@interface GameViewController ()

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

    [self generateGestureRecognizers];
}

-(void)dealloc {
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)generateGestureRecognizers {

    //Setup gesture recognizers
    UIRotationGestureRecognizer* twoFingersRotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingersRotate:)];
    [self.renderViewController.view addGestureRecognizer:twoFingersRotate];

    UIPinchGestureRecognizer* twoFingersScale = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingersScale:)];
    [self.renderViewController.view addGestureRecognizer:twoFingersScale];

    UIPanGestureRecognizer* oneFingerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerPan:)];
    [self.renderViewController.view addGestureRecognizer:oneFingerPan];

    [twoFingersRotate setDelegate:self];
    [twoFingersScale setDelegate:self];
    [oneFingerPan setDelegate:self];
}

-(void)oneFingerPan:(UIPanGestureRecognizer*)recognizer {
    CGPoint translation = [recognizer translationInView:self.renderViewController.view];
//    CGPoint location = [recognizer locationInView:self.hitView];

    //Send info to renderViewController
    [self.renderViewController translate:translation];

    //Reset recognizer so change doesn't accumulate
    [recognizer setTranslation:CGPointZero inView:self.renderViewController.view];
}

-(void)twoFingersRotate:(UIRotationGestureRecognizer*)recognizer {
    CGPoint locationInView = [recognizer locationInView:self.renderViewController.view];
    locationInView = CGPointMake(locationInView.x - self.renderViewController.view.bounds.size.width / 2, locationInView.y - self.renderViewController.view.bounds.size.height / 2);

    if ([recognizer state] == UIGestureRecognizerStateBegan || [recognizer state] == UIGestureRecognizerStateChanged) {

        //Send info to renderViewController
        [self.renderViewController rotate:locationInView radians:recognizer.rotation];

        //Reset recognizer
        [recognizer setRotation:0.0];
    }
}

-(void)twoFingersScale:(UIPinchGestureRecognizer*)recognizer {
    CGPoint locationInView = [recognizer locationInView:self.renderViewController.view];
    locationInView = CGPointMake(locationInView.x - self.renderViewController.view.bounds.size.width / 2, locationInView.y - self.renderViewController.view.bounds.size.height / 2);

    if ([recognizer state] == UIGestureRecognizerStateBegan || [recognizer state] == UIGestureRecognizerStateChanged) {

        //Send info to renderViewController
        [self.renderViewController scale:locationInView scale:recognizer.scale];

        //reset recognizer
        [recognizer setScale:1.0];
    }
}

// following allows gestures recognizers to happen simultaneously
-(BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    if (gestureRecognizer.view != otherGestureRecognizer.view) {
        return NO;
    }
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]
            || [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return NO;
    }

    return YES;
}

@end
