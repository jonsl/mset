//
// Created by Jonathan Slater on 29/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@protocol RenderingState<NSObject>

-(void)prepareToDraw;
-(NSString*)vertexShader:(Texture*)texture;
-(NSString*)fragmentShader:(Texture*)texture;

@end
