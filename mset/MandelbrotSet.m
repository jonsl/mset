//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#include <complex.h>


@implementation MandelbrotSet {
    FractalDescriptor* _fractalDescriptor;
}

-(instancetype)init {
    if ((self = [super init])) {

    }
    return self;
}

// return: number of iterations to diverge from (x, y), or -1 if convergent
-(NSInteger)calculatePoint:(double)x
                         y:(double)y {
    complex double C, Z;
    int iterations = 0;
    NSInteger const ER2 = _fractalDescriptor.escapeRadius * _fractalDescriptor.escapeRadius;

    Z = 0 + 0 * I;
    C = x + y * I;

    do {
        Z = Z * Z + C;
        ++iterations;
    } while (
            (creal(Z) * creal(Z) + cimag(Z) * cimag(Z)) <= ER2
                    && iterations < _fractalDescriptor.maxIterations
            );
    return iterations;
}

#pragma mark Fractal

-(void)compute:(unsigned char*)rgba
         width:(NSUInteger)width
        height:(NSUInteger)height
    updateDraw:(DrawBlock)updateDraw {
    if (_fractalDescriptor == nil) {
        [NSException raise:ExceptionLogicError format:@"invalid fractalDescriptor"];
    }
    // render
    for (NSUInteger y = 0; y < height; y+=2) {
        for (NSUInteger x = 0; x < width; x++) {
            double xp = ((double) x / width) * (_fractalDescriptor.xMax - _fractalDescriptor.xMin) + _fractalDescriptor.xMin; /* real point on fractal plane */
            double yp = ((double) y / height) * (_fractalDescriptor.yMax - _fractalDescriptor.yMin) + _fractalDescriptor.yMin;     /* imag - */
            NSInteger iterations = [self calculatePoint:xp y:yp];
            NSUInteger ppos = 4 * (width * y + x);
            if (iterations == _fractalDescriptor.maxIterations) {
                rgba[ppos] = 0;
                rgba[ppos + 1] = 0;
                rgba[ppos + 2] = 0;
            } else {
                double c = 3.0 * log(iterations) / log(_fractalDescriptor.maxIterations - 1.0);
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

-(FractalCoordinate)convertCoordinates:(CGPoint)point {
    FractalCoordinate fractalCoordinate;
    fractalCoordinate.x = point.x;
    fractalCoordinate.y = point.y;
    return fractalCoordinate;
}

-(FractalDescriptor*)fractalDescriptor {
    return _fractalDescriptor;
}

-(void)setFractalDescriptor:(FractalDescriptor*)fractalDescriptor {
    _fractalDescriptor = fractalDescriptor;
}

@end
