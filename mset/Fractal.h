//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

typedef void (^DrawBlock)();
typedef struct {
    double x, y;
} FractalCoordinate;

@protocol Fractal<NSObject>

-(void)compute:(unsigned char*)rgba
         width:(NSUInteger)width
        height:(NSUInteger)height
executionUnits:(NSUInteger)executionUnits
    updateDraw:(DrawBlock)updateDraw;

-(FractalCoordinate)convertCoordinates:(CGPoint)point;

@property (nonatomic, strong) FractalDescriptor* fractalDescriptor;

@end
