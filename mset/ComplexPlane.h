//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface ComplexPlane : NSObject

+(ComplexPlane*)complexPlaneWithCentre:(Real)cR cI:(Real)cI rWidth:(Real)rWidth iHeight:(Real)iHeight;

-(void)transform:(GLKMatrix4)matrix;

@property (nonatomic, readonly) Real rMin;
@property (nonatomic, readonly) Real rMax;
@property (nonatomic, readonly) Real iMin;
@property (nonatomic, readonly) Real iMax;

@end
