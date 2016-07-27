//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface MandelbrotSet : NSObject<Fractal>

+(MandelbrotSet*)mandelbrotSetWithWidth:(CGFloat)width height:(CGFloat)height;

@end
