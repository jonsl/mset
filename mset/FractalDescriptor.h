//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface FractalDescriptor : NSObject

+(FractalDescriptor*)fractalDescriptorWithXMin:(Real)xMin
                                          xMax:(Real)xMax
                                          yMin:(Real)yMin
                                          yMax:(Real)yMax
                                  escapeRadius:(NSInteger)escapeRadius
                                 maxIterations:(NSUInteger)maxIterations;

@property (nonatomic, readonly) Real xMin;
@property (nonatomic, readonly) Real xMax;
@property (nonatomic, readonly) Real yMin;
@property (nonatomic, readonly) Real yMax;
@property (nonatomic, readonly) NSInteger escapeRadius;
@property (nonatomic, readonly) NSUInteger maxIterations;

@end
