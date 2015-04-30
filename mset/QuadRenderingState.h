//
//  QuadRenderingState.h
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@class Program;
@class Texture;

@interface QuadRenderingState : NSObject<Shading>

-(void)prepareToDrawWithShading:(NSObject<Shading>*)shading;

@property (nonatomic, assign) float alpha;
@property (nonatomic, assign) GLKMatrix4 mvpMatrix;
@property (nonatomic, readonly) int aPosition;
@property (nonatomic, readonly) int aColour;
@property (nonatomic, readonly) int aTexCoords;
@property (nonatomic, readonly) int uMvpMatrix;
@property (nonatomic, readonly) int uTexture;
@property (nonatomic, readonly) int uAlpha;
@property (nonatomic, strong) Texture* texture;

@end
