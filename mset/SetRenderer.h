//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

typedef enum SetType {
    Mandelbrot, Julia
} SetType;

@interface SetRenderer : NSObject

+(instancetype)setRendererWithType:(SetType)setType numThreads:(NSUInteger)numThreads width:(float)width height:(float)height;
-(void)render;

@end
