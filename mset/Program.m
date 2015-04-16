//
// Created by Jonathan Slater on 15/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

@implementation Program {
    NSString *_vertexShader;
    NSString *_fragmentShader;
}

-(instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
{
    if ((self = [super init]))
    {
        _vertexShader = [vertexShader copy];
        _fragmentShader = [fragmentShader copy];

        [self compile];
    }
    return self;
}

-(void)compile
{
    uint program = glCreateProgram();
    uint vertexShader   = [self compileShader:_vertexShader type:GL_VERTEX_SHADER];
    uint fragmentShader = [self compileShader:_fragmentShader type:GL_FRAGMENT_SHADER];

    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);

    glLinkProgram(program);

#if DEBUG

    int linked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);

    if (!linked)
    {
        int logLength = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);

        if (logLength)
        {
            char *log = malloc(sizeof(char) * logLength);
            glGetProgramInfoLog(program, logLength, NULL, log);
            NSLog(@"Error linking program: %s", log);
            free(log);
        }
    }

#endif

    glDetachShader(program, vertexShader);
    glDetachShader(program, fragmentShader);

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    _programId = program;
}

-(uint)compileShader:(NSString *)source type:(GLenum)type
{
    uint shader = glCreateShader(type);
    if (!shader) return shader;

    const char *utfSource = [source UTF8String];

    glShaderSource(shader, 1, &utfSource, NULL);
    glCompileShader(shader);

#if DEBUG

    int compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

    if (!compiled)
    {
        int logLength = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);

        if (logLength)
        {
            char *log = malloc(sizeof(char) * logLength);
            glGetShaderInfoLog(shader, logLength, NULL, log);
            NSLog(@"Error compiling %@ shader: %s",
                    type == GL_VERTEX_SHADER ? @"vertex" : @"fragment", log);
            free(log);
        }

        glDeleteShader(shader);
        return 0;
    }

#endif

    return shader;
}

@end
