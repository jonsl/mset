//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@protocol Fractal<NSObject>

-(NSInteger)calculatePoint:(double)x
                         y:(double)y
              escapeRadius:(double)escapeRadius
             maxIterations:(NSInteger)maxIterations;

@end
