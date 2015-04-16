//
// Created by Jonathan Slater on 15/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

@interface Program()

@property (nonatomic, strong) NSString* vertexShader;
@property (nonatomic, strong) NSString* fragmentShader;
@property (nonatomic, strong) NSMutableDictionary* traitMap;

@end

@implementation Program

-(instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
{
    if ((self = [super init]))
    {
        self.vertexShader = vertexShader;
        self.fragmentShader = fragmentShader;

        [self compile];

        self.traitMap = [NSMutableDictionary dictionary];

        [self initialiseUniforms];
        [self initialiseAttributes];
    }
    return self;
}

-(void)compile
{
    uint program = glCreateProgram();
    uint vertexShader   = [self compileShader:self.vertexShader type:GL_VERTEX_SHADER];
    uint fragmentShader = [self compileShader:self.fragmentShader type:GL_FRAGMENT_SHADER];

    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);

    glLinkProgram(program);

#if DEBUG

    int linked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);

    if (!linked) {
        int logLength = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);

        if (logLength) {
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
    if (!shader) {
        return shader;
    }

    const char *utfSource = [source UTF8String];

    glShaderSource(shader, 1, &utfSource, NULL);
    glCompileShader(shader);

#if DEBUG

    int compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

    if (!compiled) {
        int logLength = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);

        if (logLength) {
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

-(void)initialiseUniforms
{
    const int MAX_NAME_LENGTH = 64;
    char rawName[MAX_NAME_LENGTH];

    int numTraits = 0;
    glGetProgramiv(_programId, GL_ACTIVE_UNIFORMS, &numTraits);
    for (int i=0; i<numTraits; ++i) {
        glGetActiveUniform(_programId, i, MAX_NAME_LENGTH, NULL, NULL, NULL, rawName);
        NSString *name = [[NSString alloc] initWithCString:rawName encoding:NSUTF8StringEncoding];
        if (self.traitMap[name] == nil) {
            self.traitMap[name] = @(glGetUniformLocation(_programId, rawName));
        } else {
            [NSException raise:@"invalid trait name" format:@"shader name collision '%@' in program %d", name, _programId];
        }
    }
}

-(void)initialiseAttributes
{
    const int MAX_NAME_LENGTH = 64;
    char rawName[MAX_NAME_LENGTH];

    int numTraits = 0;
    glGetProgramiv(_programId, GL_ACTIVE_ATTRIBUTES, &numTraits);
    for (int i=0; i<numTraits; ++i) {
        glGetActiveAttrib(_programId, i, MAX_NAME_LENGTH, NULL, NULL, NULL, rawName);
        NSString *name = [[NSString alloc] initWithCString:rawName encoding:NSUTF8StringEncoding];
        if (self.traitMap[name] == nil) {
            self.traitMap[name] = @(glGetAttribLocation(_programId, rawName));
        } else {
            [NSException raise:@"invalid trait name" format:@"shader name collision '%@' in program %d", name, _programId];
        }
    }
}

-(int)getTrait:(NSString*)name
{
    if (self.traitMap[name]) {
        return [self.traitMap[name] intValue];
    }
    return -1;
}

@end
