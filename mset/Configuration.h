//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

typedef enum FractalType {
    MandelbrotFractal, JuliaFractal
} FractalType;

@interface Configuration : NSObject<NSCoding>

+(instancetype)sharedConfiguration;

@property (nonatomic, assign) FractalType setType;

@end
