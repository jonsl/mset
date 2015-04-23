//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface ComplexPlane : NSObject

+(ComplexPlane*)complexPlaneWithOrigin:(CPPoint)origin rMaxiMin:(CPPoint)rMaxiMin rMiniMax:(CPPoint)rMiniMax;

@property (nonatomic, readonly) CPPoint origin;
@property (nonatomic, readonly) CPPoint rMaxiMin;
@property (nonatomic, readonly) CPPoint rMiniMax;

@end
