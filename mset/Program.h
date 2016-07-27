//
// Created by Jonathan Slater on 15/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface Program : NSObject

+(Program*)programWithVertexShader:(NSString*)vertexShader fragmentShader:(NSString*)fragmentShader;

-(int)getTrait:(NSString*)name;

-(int)setTrait:(NSString*)name intValue:(GLint)intValue;

-(int)setTrait:(NSString*)name floatValue:(GLfloat)floatValue;

-(int)setTrait:(NSString*)name v0:(GLfloat)v0 v1:(GLfloat)v1;

@property (nonatomic, readonly) uint name;

@end
