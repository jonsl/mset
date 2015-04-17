//
//  RendererState.m
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@interface RendererState ()

@property (nonatomic, strong) Program* program;

@end

@implementation RendererState

+(RendererState*)rendererState {
    return [[RendererState alloc] init];
}

-(instancetype)init {
    if ((self = [super init])) {
        _mvpMatrix = GLKMatrix4Identity;
    }
    return self;
}

-(void)prepare {
    if (!self.program) {
        NSString* vertexShader = [self vertexShader];
        NSString* fragmentShader = [self fragmentShader];
        self.program = [Program programWithVertexShader:vertexShader fragmentShader:fragmentShader];
    }

    _aPosition = [self.program getTrait:@"aPosition"];
    _aTexCoords = [self.program getTrait:@"aTexCoords"];
    _uMvpMatrix = [self.program getTrait:@"uMvpMatrix"];

    glUseProgram(self.program.name);
    glUniformMatrix4fv(_uMvpMatrix, 1, NO, self.mvpMatrix.m);

    if (self.texture) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, self.texture.name);
    }
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
}

-(NSString*)vertexShader {
    NSMutableString* source = [NSMutableString string];

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

-(NSString*)fragmentShader {
    NSMutableString* source = [NSMutableString string];

    [source appendLine:@"varying lowp vec2 vTexCoords;"];
    [source appendLine:@"uniform lowp sampler2D uTexture;"];

    [source appendLine:@"void main() {"];
    [source appendLine:@"  gl_FragColor = texture2D(uTexture, vTexCoords);"];
    [source appendString:@"}"];

    return source;
}

@end
