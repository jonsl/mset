//
//  Renderer.h
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@class Program;
@class Texture;

@interface Renderer : NSObject

+(Renderer*)rendererWithImageWidth:(CGFloat)width height:(CGFloat)height;
-(void)prepareStateWithTexture:(Texture*)texture;

@property (nonatomic, strong) Program* program;
@property (nonatomic, assign) GLKMatrix4 mvpMatrix;
@property (nonatomic, readonly) int uMvpMatrix;

@end
