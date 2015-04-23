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

-(void)transform:(GLKMatrix4)matrix {
    NSLog(@"complex plane pre transform: rMin=%lf, rMax=%lf, iMin=%lf, iMax=%lf}", _rMin, _rMax, _iMin, _iMax);

    GLKVector3 min = GLKMatrix4MultiplyVector3WithTranslation(matrix, GLKVector3Make((CGFloat) _rMin, (CGFloat) _iMin, 0));
    GLKVector3 max = GLKMatrix4MultiplyVector3WithTranslation(matrix, GLKVector3Make((CGFloat) _rMax, (CGFloat) _iMax, 0));

    _rMin = min.x;
    _iMin = min.y;
    _rMax = max.x;
    _iMax = max.y;

    NSLog(@"complex plane post transform rMin=%lf, rMax=%lf, iMin=%lf, iMax=%lf}", _rMin, _rMax, _iMin, _iMax);
}

@end
