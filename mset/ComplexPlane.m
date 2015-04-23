//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation ComplexPlane

+(ComplexPlane*)complexPlaneWithCentre:(Real)cR cI:(Real)cI rWidth:(Real)rWidth iHeight:(Real)iHeight {
    return [[ComplexPlane alloc] initWithCentre:cR cI:cI rWidth:rWidth iHeight:iHeight];
}

-(instancetype)initWithCentre:(Real)cR cI:(Real)cI rWidth:(Real)rWidth iHeight:(Real)iHeight {
    if ((self = [super init])) {
        _rMin = cR - rWidth / 2;
        _rMax = cR + rWidth / 2;
        _iMin = cI - iHeight / 2;
        _iMax = cI + iHeight / 2;
    }
    return self;
}

@end
