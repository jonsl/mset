//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#include <complex.h>


@implementation MandelbrotSet

-(instancetype)init {
    if ((self = [super init])) {

    }
    return self;
}

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
    return iterations;
}

#pragma mark Fractal

-(void)compute:(unsigned char*)rgba
         width:(NSInteger)width
        height:(NSInteger)height
          xMin:(double)xMin
          xMax:(double)xMax
          yMin:(double)yMin
          yMax:(double)yMax
  escapeRadius:(NSInteger)escapeRadius
 maxIterations:(NSInteger)maxIterations
    updateDraw:(DrawBlock)updateDraw {
    // render
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            double xp = ((double) x / width) * (xMax - xMin) + xMin; /* real point on fractal plane */
            double yp = ((double) y / height) * (yMax - yMin) + yMin;     /* imag - */
            NSInteger iterations = [self calculatePoint:xp y:yp escapeRadius:escapeRadius maxIterations:maxIterations];
            int ppos = 4 * (width * y + x);
            if (iterations == maxIterations) {
                rgba[ppos] = 0;
                rgba[ppos + 1] = 0;
                rgba[ppos + 2] = 0;
            } else {
                double c = 3.0 * log(iterations) / log(maxIterations - 1.0);
                if (c < 1) {
                    rgba[ppos] = (unsigned char) (255.0 * c);
                    rgba[ppos + 1] = 0;
                    rgba[ppos + 2] = 0;
                } else if (c < 2) {
                    rgba[ppos] = 255;
                    rgba[ppos + 1] = (unsigned char) (255.0 * (c - 1));
                    rgba[ppos + 2] = 0;
                } else {
                    rgba[ppos] = 255;
                    rgba[ppos + 1] = 255;
                    rgba[ppos + 2] = (unsigned char) (255.0 * (c - 2));
                }
            }
            rgba[ppos + 3] = 0xff;
        }
    }
    if (updateDraw) {
        updateDraw();
    }
}

@end
