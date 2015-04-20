//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface FractalDescriptor : NSObject

+(FractalDescriptor*)fractalDescriptorWithXMin:(double)xMin
                                          xMax:(double)xMax
                                          yMin:(double)yMin
                                          yMax:(double)yMax
                                  escapeRadius:(NSInteger)escapeRadius
                                 maxIterations:(NSUInteger)maxIterations;

@property (nonatomic, readonly) double xMin;
@property (nonatomic, readonly) double xMax;
@property (nonatomic, readonly) double yMin;
@property (nonatomic, readonly) double yMax;
@property (nonatomic, readonly) NSInteger escapeRadius;
@property (nonatomic, readonly) NSUInteger maxIterations;

@end
