//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

@implementation ComplexPlane

+(ComplexPlane*)complexPlaneWithOrigin:(Point2)origin rMaxiMin:(Point2)rMaxiMin rMiniMax:(Point2)rMiniMax {
    return [[ComplexPlane alloc] initPlaneWithOrigin:origin rMaxiMin:rMaxiMin rMiniMax:rMiniMax];
}

-(instancetype)initPlaneWithOrigin:(Point2)origin rMaxiMin:(Point2)rMaxiMin rMiniMax:(Point2)rMiniMax {
    if ((self = [super init])) {
        _origin = origin;
        _rMaxiMin = rMaxiMin;
        _rMiniMax = rMiniMax;
    }
    return self;
}

-(Point2)screenPointToComplexPlane:(Point2)position screenSize:(CGSize)screenSize {
    Real xLen = position.x / screenSize.width;
    Real yLen = position.y / screenSize.height;
    Point2 pp;
    pp.r = self.origin.r
            + xLen * (self.rMaxiMin.r - self.origin.r)
            + yLen * (self.rMiniMax.r - self.origin.r);
    pp.i = self.origin.i
            + yLen * (self.rMiniMax.i - self.origin.i)
            + xLen * (self.rMaxiMin.i - self.origin.i);
    return pp;
}

@end
