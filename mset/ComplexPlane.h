//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "point2.h"

@interface ComplexPlane : NSObject

+(ComplexPlane*)complexPlaneWithOrigin:(Point2)origin rMaxiMin:(Point2)rMaxiMin rMiniMax:(Point2)rMiniMax;
-(Point2)screenPointToComplexPlane:(Point2)position screenSize:(CGSize)screenSize;

@property (nonatomic, readonly) Point2 origin;
@property (nonatomic, readonly) Point2 rMaxiMin;
@property (nonatomic, readonly) Point2 rMiniMax;

@end
