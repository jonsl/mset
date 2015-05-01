//
// Created by Jonathan Slater on 20/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

// REF: https://solarianprogrammer.com/2013/02/28/mandelbrot-set-cpp-11/

@implementation PolynomialColourMap

@synthesize rgb = _rgb;
@synthesize size = _size;

-(instancetype)initWithSize:(NSUInteger)size {
    if ((self = [super init])) {
        _rgb = calloc(size * 3, sizeof(unsigned char));
        for (int index = 0; index < size; ++index) {
            int ppos = index * 3;
            double t = (double)index / (double)size;
            _rgb[ppos] = (unsigned char)(5 * (1 - t) * t * t * t * 255);
            _rgb[ppos + 1] = (unsigned char)(15 * (1 - t) * (1 - t) * t * t * 255);
            _rgb[ppos + 2] = (unsigned char)(8.5 * (1 - t) * (1 - t) * (1 - t) * t * 255);
        }
        _size = size * 3 * sizeof(unsigned char);
    }
    return self;
}

-(void)dealloc {
    free(_rgb);
    _rgb = 0;
}

@end
