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

-(CPPoint)screenPointToComplexPlane:(CGPoint)position screenSize:(CGSize)screenSize {
    Real xLen = (Real)position.x / screenSize.width;
    Real yLen = (Real)position.y / screenSize.height;
    CPPoint pp;
    pp.r = self.origin.r
            + xLen * (self.rMaxiMin.r - self.origin.r)
            + yLen * (self.rMiniMax.r - self.origin.r);
    pp.i = self.origin.i
            + yLen * (self.rMiniMax.i - self.origin.i)
            + xLen * (self.rMaxiMin.i - self.origin.i);
    return pp;
}

@end
