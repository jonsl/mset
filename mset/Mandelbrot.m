//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#include <complex.h>


@implementation Mandelbrot

#pragma mark Fractal

// return: number of iterations to diverge from x, y, or -1 if convergent
-(NSInteger)calculatePoint:(double)x
                         y:(double)y
              escapeRadius:(double)escapeRadius
             maxIterations:(NSInteger)maxIterations {
    complex double C, Z;
    int i = 0;

    Z = 0 + 0 * I;
    C = x + y * I;

    do {
        Z = Z * Z + C;
        i++;
    } while ((creal(Z) * creal(Z) + cimag(Z) * cimag(Z)) <= (escapeRadius * escapeRadius) && i < maxIterations);

    if (i >= maxIterations) {
        return -1;
    }
    return i;
}

@end
