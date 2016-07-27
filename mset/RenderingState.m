//
//  RenderingState.m
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation RenderingState

-(instancetype)init {
    if ((self = [super init])) {
        _mvpMatrix = GLKMatrix4Identity;
        _alpha = 1.0f;
    }
    return self;
}

-(void)prepareToDrawWithVertexShader:(NSString*)vertexShader fragmentShader:(NSString*)fragmentShader {
    if (!self.program) {
        NSString* vsh = vertexShader;
        NSString* fsh = fragmentShader;
        if (vsh == nil || fsh == nil) {
            vsh = [self vertexShader:_texture];
            fsh = [self fragmentShader:_texture];
        }
        self.program = [Program programWithVertexShader:vsh fragmentShader:fsh];
    }
    glUseProgram(self.program.name);

    int uMvpMatrix = [self.program getTrait:@"u_mvpMatrix"];
    if (uMvpMatrix != -1) {
        glUniformMatrix4fv(uMvpMatrix, 1, NO, self.mvpMatrix.m);
    }
    int uAlpha = [self.program getTrait:@"u_alpha"];
    if (uAlpha != -1) {
        glUniform4f(uAlpha, 1.0f, 1.0f, 1.0f, _alpha);
    }
    if (self.texture) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, self.texture.name);
        int uTexture = [self.program getTrait:@"u_texture"];
        if (uTexture != -1) {
            glUniform1i(uTexture, 0);
        }
    }
#ifdef DEBUG
    GLenum glError = glGetError();
    NSAssert(glError == GL_NO_ERROR, @"glError is %d", glError);
#endif
}

-(NSString*)vertexShader:(Texture*)texture {
    BOOL hasTexture = texture != nil;
    NSMutableString* source = [NSMutableString string];

    [source appendLine:@"attribute vec4 a_position;"];
    [source appendLine:@"attribute vec4 a_colour;"];
    if (hasTexture) {
        [source appendLine:@"attribute vec2 a_texCoords;"];
    }
    [source appendLine:@"uniform mat4 u_mvpMatrix;"];
    [source appendLine:@"uniform vec4 u_alpha;"];
    [source appendLine:@"varying lowp vec4 v_colour;"];
    if (hasTexture) {
        [source appendLine:@"varying lowp vec2 v_texCoords;"];
    }

    [source appendLine:@"void main() {"];
    [source appendLine:@"  gl_Position = u_mvpMatrix * a_position;"];
    [source appendLine:@"  v_colour = a_colour * u_alpha;"];
    if (hasTexture) {
        [source appendLine:@"  v_texCoords  = a_texCoords;"];
    }
    [source appendString:@"}"];

    return source;
}

-(NSString*)fragmentShader:(Texture*)texture {
    BOOL hasTexture = texture != nil;
    NSMutableString* source = [NSMutableString string];

    [source appendLine:@"varying lowp vec4 v_colour;"];
    if (hasTexture) {
        [source appendLine:@"varying lowp vec2 v_texCoords;"];
        [source appendLine:@"uniform lowp sampler2D u_texture;"];
    }

    [source appendLine:@"void main() {"];
    if (hasTexture) {
        [source appendLine:@"  gl_FragColor = texture2D(u_texture, v_texCoords) * v_colour;"];
    } else {
        [source appendLine:@"  gl_FragColor = v_colour;"];
    }
    [source appendString:@"}"];

    return source;
}

-(void)setAlpha:(float)alpha {
    if ((alpha >= 1.0f && _alpha < 1.0f) || (alpha < 1.0f && _alpha >= 1.0f)) {
        self.program = nil;
    }
    _alpha = alpha;
}

-(void)setTexture:(Texture*)texture {
    if ((_texture && !texture) || (!_texture && texture)) {
        self.program = nil;
    }
    _texture = texture;
}

@end
