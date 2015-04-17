//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#include <complex.h>


@implementation Mandelbrot

-(instancetype)init {
    if ((self = [super init])) {

    }
    return self;
}

#pragma mark Fractal

// return: number of iterations to diverge from (x, y), or -1 if convergent
-(NSInteger)calculatePoint:(double)x
                         y:(double)y
              escapeRadius:(double)escapeRadius
             maxIterations:(NSInteger)maxIterations {
    complex double C, Z;
    int iterations = 0;

    Z = 0 + 0 * I;
    C = x + y * I;

    do {
        Z = Z * Z + C;
        ++iterations;
    } while (
            (creal(Z) * creal(Z) + cimag(Z) * cimag(Z)) <= (escapeRadius * escapeRadius)
                    && iterations < maxIterations
            );

    if (iterations >= maxIterations) {
        return -1;
    }
    return iterations;
}

@end
