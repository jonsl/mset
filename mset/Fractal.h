//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Util.h"

typedef void (^DrawBlock)();
typedef struct {
    Real x, y;
} FractalCoordinate;

@protocol Fractal<NSObject>

@required
-(void)compute:(unsigned char*)rgba
         width:(NSUInteger)width
        height:(NSUInteger)height
  escapeRadius:(NSInteger)escapeRadius
 maxIterations:(NSUInteger)maxIterations
     colourMap:(NSObject<ColourMapping>*)colourMap
executionUnits:(NSUInteger)executionUnits
    updateDraw:(DrawBlock)updateDraw;

@property (nonatomic, strong) ComplexPlane* complexPlane;
@property (nonatomic, strong) NSObject<Shading>* shader;

@end
