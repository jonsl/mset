//
//  RenderViewController.h
//  mset
//
//  Created by Jonathan Slater on 22/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface RenderViewController : GLKViewController

-(void)translate:(CGPoint)location;
-(void)rotateWithCentre:(CGPoint)centre radians:(CGFloat)radians;
-(void)scaleWithCentre:(CGPoint)centre scale:(CGFloat)scale;
-(void)translateEnded;
-(void)rotateEnded;
-(void)scaleEnded;

@end
