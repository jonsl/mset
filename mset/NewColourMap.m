//
// Created by Jonathan Slater on 20/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation NewColourMap

@synthesize rgb = _rgb;
@synthesize size = _size;

-(instancetype)initWithSize:(NSUInteger)size {
    if ((self = [super init])) {
        _rgb = calloc(size * 3, sizeof(unsigned char));
        for (int index = 0; index < size; ++index) {
            int ppos = index * 3;
            if (index >= 512) {
                _rgb[ppos] = (unsigned char)(index - 512);
                _rgb[ppos + 1] = (unsigned char)(255 - _rgb[ppos]);
                _rgb[ppos + 2] = 0;
            }
            else if (index >= 256) {
                _rgb[ppos + 1] = (unsigned char)(index - 256);
                _rgb[ppos + 2] = (unsigned char)(255 - _rgb[ppos + 1]);
                _rgb[ppos] = 0;
            }
            else {
                _rgb[ppos] = 0;
                _rgb[ppos + 1] = 0;
                _rgb[ppos + 2] = (unsigned char)index;
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
