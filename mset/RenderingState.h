//
//  RenderingState.h
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface RenderingState : NSObject

-(void)prepareToDrawWithVertexShader:(NSString*)vertexShader fragmentShader:(NSString*)fragmentShader;

@property (nonatomic, strong) Program* program;
@property (nonatomic, assign) float alpha;
@property (nonatomic, assign) GLKMatrix4 mvpMatrix;
@property (nonatomic, strong) Texture* texture;

@end
