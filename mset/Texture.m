//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Texture.h"


@implementation Texture {

}

-(instancetype)initWithWidth:(float)width height:(float)height
{
    if ((self = [super init]))
    {
    }
    return self;
}

+(uint)nextPowerOfTwo:(uint)value
{
    unsigned int v = value; // compute the next highest power of 2 of 32-bit v

    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;

    return v;
}

@end
