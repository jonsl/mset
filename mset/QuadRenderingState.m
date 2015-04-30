//
//  QuadRenderingState.m
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@interface QuadRenderingState ()

@property (nonatomic, strong) Program* program;

@end

@implementation QuadRenderingState

-(instancetype)init {
    if ((self = [super init])) {
        _mvpMatrix = GLKMatrix4Identity;
        _alpha = 1.0f;
    }
    return self;
}

-(void)prepareToDrawWithShading:(NSObject<Shading>*)shading {
    if (!self.program) {
        if (!self.program) {
            if (shading) {
                self.program = [Program programWithVertexShader:[shading vertexShader:_texture]
                                                 fragmentShader:[shading fragmentShader:_texture]];
            } else {
                self.program = [Program programWithVertexShader:[self vertexShader:_texture]
                                                 fragmentShader:[self fragmentShader:_texture]];
            }
        }
    }

    _aPosition = [self.program getTrait:@"aPosition"];
    _aColour = [self.program getTrait:@"aColour"];
    _aTexCoords = [self.program getTrait:@"aTexCoords"];
    _uMvpMatrix = [self.program getTrait:@"uMvpMatrix"];
    _uAlpha = [self.program getTrait:@"uAlpha"];
    _uTexture = [self.program getTrait:@"uTexture"];

    glUseProgram(self.program.name);
    glUniformMatrix4fv(_uMvpMatrix, 1, NO, self.mvpMatrix.m);

    glUniform4f(_uAlpha, 1.0f, 1.0f, 1.0f, _alpha);

    if (self.texture) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, self.texture.name);
        glUniform1i(_uTexture, 0);
    }
#ifdef DEBUG
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
#endif
}

-(NSString*)vertexShader:(Texture*)texture {
    BOOL hasTexture = texture != nil;
    NSMutableString* source = [NSMutableString string];

    [source appendLine:@"attribute vec4 aPosition;"];
    [source appendLine:@"attribute vec4 aColour;"];
    if (hasTexture) {
        [source appendLine:@"attribute vec2 aTexCoords;"];
    }
    [source appendLine:@"uniform mat4 uMvpMatrix;"];
    [source appendLine:@"uniform vec4 uAlpha;"];
    [source appendLine:@"varying lowp vec4 vColour;"];
    if (hasTexture) {
        [source appendLine:@"varying lowp vec2 vTexCoords;"];
    }

    [source appendLine:@"void main() {"];
    [source appendLine:@"  gl_Position = uMvpMatrix * aPosition;"];
    [source appendLine:@"  vColour = aColour * uAlpha;"];
    if (hasTexture) {
        [source appendLine:@"  vTexCoords  = aTexCoords;"];
    }
    [source appendString:@"}"];

    return source;
}

-(NSString*)fragmentShader:(Texture*)texture {
    BOOL hasTexture = texture != nil;
    NSMutableString* source = [NSMutableString string];

    [source appendLine:@"varying lowp vec4 vColour;"];
    if (hasTexture) {
        [source appendLine:@"varying lowp vec2 vTexCoords;"];
        [source appendLine:@"uniform lowp sampler2D uTexture;"];
    }

    [source appendLine:@"void main() {"];
    if (hasTexture) {
        [source appendLine:@"  gl_FragColor = texture2D(uTexture, vTexCoords) * vColour;"];
    } else {
        [source appendLine:@"  gl_FragColor = vColour;"];
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
