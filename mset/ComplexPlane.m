//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation ComplexPlane

+(ComplexPlane*)complexPlaneWithOrigin:(CPPoint)origin rMaxiMin:(CPPoint)rMaxiMin rMiniMax:(CPPoint)rMiniMax {
    return [[ComplexPlane alloc] initPlaneWithOrigin:origin rMaxiMin:rMaxiMin rMiniMax:rMiniMax];
}

-(instancetype)initPlaneWithOrigin:(CPPoint)origin rMaxiMin:(CPPoint)rMaxiMin rMiniMax:(CPPoint)rMiniMax {
    if ((self = [super init])) {
        _origin = origin;
        _rMaxiMin = rMaxiMin;
        _rMiniMax = rMiniMax;
    }
    return self;
}

@end
