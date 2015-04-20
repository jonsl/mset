//
// Created by Jonathan Slater on 20/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation DefaultColourMap

@synthesize rgb = _rgb;
@synthesize size = _size;

-(instancetype)initWithSize:(NSUInteger)size {
    if ((self = [super init])) {
        _rgb = calloc(size * 3, sizeof(unsigned char));
        for (int index = 0; index < size; ++index) {
            int ppos = index * 3;
            double c = 3.0 * log(index) / log(size - 1.0);
            if (c < 1) {
                _rgb[ppos] = (unsigned char) (255 * c);
                _rgb[ppos + 1] = 0;
                _rgb[ppos + 2] = 0;
            } else if (c < 2) {
                _rgb[ppos] = 255;
                _rgb[ppos + 1] = (unsigned char) (255 * (c - 1));
                _rgb[ppos + 2] = 0;
            } else {
                _rgb[ppos] = 255;
                _rgb[ppos + 1] = 255;
                _rgb[ppos + 2] = (unsigned char) (255 * (c - 2));
            }
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
