//
// Created by Jonathan Slater on 18/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation FractalDescriptor

+(FractalDescriptor*)fractalDescriptorWithXMin:(double)xMin
                                          xMax:(double)xMax
                                          yMin:(double)yMin
                                          yMax:(double)yMax
                                  escapeRadius:(NSInteger)escapeRadius
                                 maxIterations:(NSInteger)maxIterations {
    return [[FractalDescriptor alloc] initWithXMin:xMin
                                              xMax:xMax
                                              yMin:yMin
                                              yMax:yMax
                                      escapeRadius:escapeRadius
                                     maxIterations:maxIterations];
}

-(instancetype)initWithXMin:(double)xMin
                       xMax:(double)xMax
                       yMin:(double)yMin
                       yMax:(double)yMax
               escapeRadius:(NSInteger)escapeRadius
              maxIterations:(NSInteger)maxIterations {
    if ((self = [super init])) {
        _xMin = xMin;
        _xMax = xMax;
        _yMin = yMin;
        _yMax = yMax;
        _escapeRadius = escapeRadius;
        _maxIterations = maxIterations;
    }
    return self;
}

@end
