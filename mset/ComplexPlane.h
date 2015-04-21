//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface ComplexPlane : NSObject

+(ComplexPlane*)complexPlaneWithXMax:(Real)xMin xMax:(Real)xMax yMin:(Real)yMin yMax:(Real)yMax;

@property (nonatomic, readonly) Real xMin;
@property (nonatomic, readonly) Real xMax;
@property (nonatomic, readonly) Real yMin;
@property (nonatomic, readonly) Real yMax;

@end
