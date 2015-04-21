//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation ComplexPlane

+(ComplexPlane*)complexPlaneWithXMax:(Real)xMin xMax:(Real)xMax yMin:(Real)yMin yMax:(Real)yMax {
    return [[ComplexPlane alloc] initWithXMin:xMin xMax:xMax yMin:yMin yMax:yMax];
}

-(instancetype)initWithXMin:(Real)xMin xMax:(Real)xMax yMin:(Real)yMin yMax:(Real)yMax {
    if ((self = [super init])) {
        _xMin = xMin;
        _xMax = xMax;
        _yMin = yMin;
        _yMax = yMax;
    }
    return self;
}

@end
