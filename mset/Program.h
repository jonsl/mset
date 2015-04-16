//
// Created by Jonathan Slater on 15/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface Program : NSObject

+(Program*)programWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader;
-(int)getTrait:(NSString*)name;

@property (nonatomic, readonly) uint name;

@end
