//
//  Renderer.m
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

typedef struct {
    unsigned char r, g, b;
} rgb_t;

@interface Renderer()

@property (nonatomic, assign) CGPoint size;

@end

@implementation Renderer {
    NSMutableDictionary *_programs;

    GLKMatrix4 _mvpMatrix;

    float _alpha;
    BOOL _premultipliedAlpha;

    int _aPosition;
    int _aTexCoords;
};

-(instancetype)initWithImageWidth:(CGFloat)width height:(CGFloat)height
{
    if ((self = [super init])) {
        _programs = [[NSMutableDictionary alloc] init];
        _mvpMatrix = GLKMatrix4Identity;
        self.size = CGPointMake(width, height);
    }
    return self;
}

-(void)prepareStateWithTexture:(uint)textureId
{
    if (!_program) {
        NSString *vertexShader = [self vertexShader];
        NSString *fragmentShader = [self fragmentShader];
        _program = [[Program alloc] initWithVertexShader:vertexShader fragmentShader:fragmentShader];
    }

    _aPosition  = [_program getTrait:@"aPosition"];
    _aTexCoords = [_program getTrait:@"aTexCoords"];
    _uMvpMatrix = [_program getTrait:@"uMvpMatrix"];

    glUseProgram(_program.programId);
    glUniformMatrix4fv(_uMvpMatrix, 1, NO, _mvpMatrix.m);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureId);
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
