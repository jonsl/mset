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

+(Program*)programWithVertexShader:(NSString*)vertexShader fragmentShader:(NSString*)fragmentShader {
    return [[Program alloc] initWithVertexShader:vertexShader fragmentShader:fragmentShader];
}

-(instancetype)initWithVertexShader:(NSString*)vertexShader fragmentShader:(NSString*)fragmentShader {
    if ((self = [super init])) {
        self.vertexShader = vertexShader;
        self.fragmentShader = fragmentShader;

        [self compile];

        self.traitMap = [NSMutableDictionary dictionary];

        [self initialiseTraits];
    }
    return self;
}

-(void)dealloc {
    glDeleteProgram(_name);
    _name = 0;
}

-(void)compile {
    uint program = glCreateProgram();

    uint vertexShader;
    if (self.vertexShader) {
        vertexShader = [self compileShader:self.vertexShader type:GL_VERTEX_SHADER];
        glAttachShader(program, vertexShader);
    }
    uint fragmentShader;
    if (self.fragmentShader) {
        fragmentShader = [self compileShader:self.fragmentShader type:GL_FRAGMENT_SHADER];
        glAttachShader(program, fragmentShader);
    }
    glLinkProgram(program);

#ifdef DEBUG
    int linked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);

    if (!linked) {
        GLint logLength = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);

        if (logLength) {
            char* log = malloc(sizeof(char) * (size_t)logLength);
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

    _name = program;
}

-(uint)compileShader:(NSString*)source type:(GLenum)type {
    uint shader = glCreateShader(type);
    if (!shader) {
        return shader;
    }

    const char* utfSource = [source UTF8String];

    glShaderSource(shader, 1, &utfSource, NULL);
    glCompileShader(shader);

#ifdef DEBUG
    int compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

    if (!compiled) {
        GLint logLength = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);

        if (logLength) {
            char* log = malloc(sizeof(char) * (size_t)logLength);
            glGetShaderInfoLog(shader, logLength, NULL, log);
            NSLog(@"Error compiling %@ shader: %s", type == GL_VERTEX_SHADER ? @"vertex" : @"fragment", log);
            free(log);
        }

        glDeleteShader(shader);
        return 0;
    }
#endif

    return shader;
}

-(void)initialiseTraits {
    const int MAX_NAME_LENGTH = 64;
    char rawName[MAX_NAME_LENGTH];
    // uniforms
    int numTraits = 0;
    glGetProgramiv(_name, GL_ACTIVE_UNIFORMS, &numTraits);
    for (GLuint i = 0; i < numTraits; ++i) {
        glGetActiveUniform(_name, i, MAX_NAME_LENGTH, NULL, NULL, NULL, rawName);
        NSString* name = [[NSString alloc] initWithCString:rawName encoding:NSUTF8StringEncoding];
        if (self.traitMap[name] == nil) {
            self.traitMap[name] = @(glGetUniformLocation(_name, rawName));
        } else {
            [NSException raise:ExceptionLogicError format:@"shader uniform collision '%@' in program %d", name, _name];
        }
    }
    // attributes
    glGetProgramiv(_name, GL_ACTIVE_ATTRIBUTES, &numTraits);
    for (GLuint i = 0; i < numTraits; ++i) {
        glGetActiveAttrib(_name, i, MAX_NAME_LENGTH, NULL, NULL, NULL, rawName);
        NSString* name = [[NSString alloc] initWithCString:rawName encoding:NSUTF8StringEncoding];
        if (self.traitMap[name] == nil) {
            self.traitMap[name] = @(glGetAttribLocation(_name, rawName));
        } else {
            [NSException raise:ExceptionLogicError format:@"shader attribute collision '%@' in program %d", name, _name];
        }
    }
#ifdef DEBUG
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
#endif
}

-(int)getTrait:(NSString*)name {
    if (self.traitMap[name]) {
        return [self.traitMap[name] intValue];
    }
    return -1;
}

@end
