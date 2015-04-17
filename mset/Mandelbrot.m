//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#include <complex.h>


@implementation Mandelbrot

/* The magnitude of a complex number */
static double magnitude(complex double c) {
    return sqrt(creal(c) * creal(c) + cimag(c) * cimag(c));
}

/* This is where the actual mandelbrot magic happens. Thanks to C99, it's tiny.
 * Return the number of iterations to diverge from x,y, or -1 if convergent
 * (ie, doesn't diverge within 'iteration' iterations). */
-(NSInteger)calculatePoint:(double)x y:(double)y iterations:(NSInteger)iterations {
    complex double C, Z;
    int i = 0;

    Z = 0 + 0 * I;
    C = x + y * I;

    do {
        Z = Z * Z + C;
        i++;
    } while (magnitude(Z) < 2 && i < iterations);

    if (i >= iterations) return -1;
    return i;

}

@end
