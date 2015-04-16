//
//  Renderer.m
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

@interface Renderer()

@property (nonatomic, assign) CGPoint size;

@end

@implementation Renderer {
    NSMutableDictionary *_programs;

    int _aPosition;
    int _aTexCoords;
};

+(Renderer*)rendererWithImageWidth:(CGFloat)width height:(CGFloat)height
{
    return [[Renderer alloc] initWithImageWidth:width height:height];
}

-(instancetype)initWithImageWidth:(CGFloat)width height:(CGFloat)height
{
    if ((self = [super init])) {
        _programs = [[NSMutableDictionary alloc] init];
        _mvpMatrix = GLKMatrix4Identity;
        self.size = CGPointMake(width, height);
    }
    return self;
}

-(void)prepareStateWithTexture:(Texture*)texture
{
    if (!_program) {
        NSString *vertexShader = [self vertexShader];
        NSString *fragmentShader = [self fragmentShader];
        _program = [Program programWithVertexShader:vertexShader fragmentShader:fragmentShader];
    }

    _aPosition  = [_program getTrait:@"aPosition"];
    _aTexCoords = [_program getTrait:@"aTexCoords"];
    _uMvpMatrix = [_program getTrait:@"uMvpMatrix"];

    glUseProgram(_program.name);
    glUniformMatrix4fv(_uMvpMatrix, 1, NO, _mvpMatrix.m);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture.name);
}

-(NSString*)vertexShader
{
    NSMutableString *source = [NSMutableString string];
    
    [source appendLine:@"attribute vec4 aPosition;"];
    [source appendLine:@"attribute vec2 aTexCoords;"];
    [source appendLine:@"uniform mat4 uMvpMatrix;"];
    [source appendLine:@"varying lowp vec2 vTexCoords;"];

    [source appendLine:@"void main() {"];
    [source appendLine:@"  gl_Position = uMvpMatrix * aPosition;"];
    [source appendLine:@"  vTexCoords  = aTexCoords;"];
    [source appendString:@"}"];
    
    return source;
}

-(NSString*)fragmentShader
{
    NSMutableString *source = [NSMutableString string];

    [source appendLine:@"varying lowp vec2 vTexCoords;"];
    [source appendLine:@"uniform lowp sampler2D uTexture;"];

    [source appendLine:@"void main() {"];
    [source appendLine:@"  gl_FragColor = texture2D(uTexture, vTexCoords);"];
    [source appendString:@"}"];
    
    return source;
}

@end
