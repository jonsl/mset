//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@protocol Fractal<NSObject>

@required
-(void)renderWithMaxIterations:(NSInteger)maxIterations;

@property (nonatomic, strong) ComplexPlane* complexPlane;

@end
