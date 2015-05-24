//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@protocol Fractal<DisplayObject>

@required
-(void)updateWithComplexPlane:(ComplexPlane*)complexPlane screenSize:(CGSize)screenSize;

@property (nonatomic, strong) ComplexPlane* complexPlane;

@end
