//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation Texture

+(instancetype)textureWithWidth:(float)width height:(float)height scale:(float)scale {
    return [[Texture alloc] initWithWidth:width height:height scale:scale];
}

-(instancetype)initWithWidth:(float)width height:(float)height scale:(float)scale {
    if ((self = [super init])) {
        // only textures with sidelengths that are powers of 2 support all OpenGL ES features.
        NSUInteger width2 = [Texture nextPowerOfTwo:width * scale];
        NSUInteger height2 = [Texture nextPowerOfTwo:height * scale];
        NSUInteger const bytesPerPixel = 4;
        _imageData = calloc(width2 * height2 * bytesPerPixel, sizeof(uint8_t));
        [self createGlTexture:_imageData width:width2 height:height2 numMipmaps:0];

        _width = width2;
        _height = height2;
        _scale = scale;

        // invoke setters
        self.repeat = NO;
        self.filter = LinearFilter;
    }
    return self;
}

-(void)dealloc {
    glDeleteTextures(1, &_name);
    _name = 0;
    free(_imageData);
    _imageData = 0;
}

-(void)setPixel:(uint)index rgba:(uint32_t)rgba {
    NSAssert(sizeof(uint32_t) == 4, @"invalid size");
    NSAssert(index < _width * _height, @"invalid index");
    ((uint32_t*) _imageData)[index] = rgba;
}

-(void)createGlTexture:(const void*)imgData
                 width:(NSUInteger)width
                height:(NSUInteger)height
            numMipmaps:(NSUInteger)numMipmaps {
    GLenum glTexType = GL_UNSIGNED_BYTE;
    GLenum glTexFormat = GL_RGBA;
    int bitsPerPixel = 32;

    _name = 0;
    glGenTextures(1, &_name);
    NSAssert(_name != 0, @"invalid texture name");
    glBindTexture(GL_TEXTURE_2D, _name);

    int levelWidth = (int) width;
    int levelHeight = (int) height;
    unsigned char* levelData = (unsigned char*) imgData;
    for (int level = 0; level <= numMipmaps; ++level) {
        int size = levelWidth * levelHeight * bitsPerPixel / 8;
        glTexImage2D(GL_TEXTURE_2D, level, (GLint) glTexFormat, levelWidth, levelHeight,
                0, glTexFormat, glTexType, levelData);
        levelData += size;
        levelWidth /= 2;
        levelHeight /= 2;
    }
    glBindTexture(GL_TEXTURE_2D, 0);

    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
}

-(void)replace {
    glBindTexture(GL_TEXTURE_2D, _name);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _width, _height, GL_RGBA, GL_UNSIGNED_BYTE, _imageData);
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
}

-(void)setRepeat:(BOOL)value {
    _repeat = value;
    glBindTexture(GL_TEXTURE_2D, _name);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _repeat ? GL_REPEAT : GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _repeat ? GL_REPEAT : GL_CLAMP_TO_EDGE);
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
}

-(void)setFilter:(TextureFilter)textureFilter {
    glBindTexture(GL_TEXTURE_2D, _name);
    GLint minFilter, magFilter;
    switch (textureFilter) {
        case NoFilter: {
            minFilter = magFilter = GL_NEAREST;
            break;
        }
        case LinearFilter: {
            minFilter = magFilter = GL_LINEAR;
            break;
        }
    }
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
}

+(NSUInteger)nextPowerOfTwo:(NSUInteger)value {
    // REF: https://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2
    NSUInteger v = value;
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    return v;
}

@end
