//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

typedef void (^DrawBlock)();

@protocol Fractal<NSObject>

-(void)compute:(unsigned char*)rgba
         width:(NSInteger)width
        height:(NSInteger)height
          xMin:(double)xMin
          xMax:(double)xMax
          yMin:(double)yMin
          yMax:(double)yMax
  escapeRadius:(NSInteger)escapeRadius
 maxIterations:(NSInteger)maxIterations
    updateDraw:(DrawBlock)updateDraw;

@end
