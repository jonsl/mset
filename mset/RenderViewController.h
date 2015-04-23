//
//  RenderViewController.h
//  mset
//
//  Created by Jonathan Slater on 22/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface RenderViewController : GLKViewController

-(void)translate:(CGPoint)location;
-(void)rotate:(CGPoint)location radians:(CGFloat)radians;
-(void)scale:(CGPoint)location scale:(CGFloat)scale;
-(void)translateEnded;
-(void)rotateEnded;
-(void)scaleEnded;

@end
