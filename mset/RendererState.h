//
//  RendererState.h
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@class Program;
@class Texture;

@interface RendererState : NSObject

+(RendererState*)rendererState;

-(void)prepareState;

@property (nonatomic, assign) GLKMatrix4 mvpMatrix;
@property (nonatomic, readonly) int aPosition;
@property (nonatomic, readonly) int aTexCoords;
@property (nonatomic, readonly) int uMvpMatrix;
@property (nonatomic, strong) Texture* texture;

@end
