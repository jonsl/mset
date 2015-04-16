//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Texture.h"


@implementation Texture {
    float _width;
    float _height;
    float _scale;
    uint _name;
    unsigned char* _imageData;
}

+(instancetype)textureWithWidth:(float)width height:(float)height scale:(float)scale
{
    return [[Texture alloc] initWithWidth:width height:height scale:scale];
}

-(instancetype)initWithWidth:(float)width height:(float)height scale:(float)scale
{
    if ((self = [super init])) {
        // only textures with sidelengths that are powers of 2 support all OpenGL ES features.
        int width2 = [Texture nextPowerOfTwo:width * scale];
        int height2 = [Texture nextPowerOfTwo:height * scale];

        CGColorSpaceRef cgColorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        int bytesPerPixel = 4;

        _imageData = calloc(width2 * height2 * bytesPerPixel, sizeof(unsigned char));
        CGContextRef context = CGBitmapContextCreate(_imageData, width2, height2, 8, bytesPerPixel * width2, cgColorSpace, bitmapInfo);
        CGColorSpaceRelease(cgColorSpace);

        // UIKit referential is upside down - we flip it and apply the scale factor
        CGContextTranslateCTM(context, 0.0f, height2);
        CGContextScaleCTM(context, scale, -scale);

        [self createGlTexture:_imageData width:width2 height:height2 numMipmaps:0];

        CGContextRelease(context);
        free(_imageData);

        _width = width2;
        _height = height2;
        _scale = scale;

        self.repeat = NO;
    }
    return self;
}

- (void)dealloc
{
    glDeleteTextures(1, &_name);
}

+(uint)nextPowerOfTwo:(uint)value
{
    unsigned int v = value; // compute the next highest power of 2 of 32-bit v

    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;

    return v;
}

-(void)createGlTexture:(const void *)imgData width:(uint)width height:(uint)height numMipmaps:(uint)numMipmaps
{
    GLenum glTexType = GL_UNSIGNED_BYTE;
    GLenum glTexFormat = GL_RGBA;
    int bitsPerPixel = 32;

    glGenTextures(1, &_name);
    glBindTexture(GL_TEXTURE_2D, _name);

    int levelWidth  = width;
    int levelHeight = height;
    unsigned char *levelData = (unsigned char *)imgData;

    for (int level=0; level<=numMipmaps; ++level) {
        int size = levelWidth * levelHeight * bitsPerPixel / 8;
        glTexImage2D(GL_TEXTURE_2D, level, glTexFormat, levelWidth, levelHeight,
                0, glTexFormat, glTexType, levelData);
        levelData += size;
        levelWidth  /= 2;
        levelHeight /= 2;
    }
    glBindTexture(GL_TEXTURE_2D, 0);

    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:@"invalid texture" format:@"glError is %d", glError];
    }
}

-(unsigned char*)rgba
{
    return _imageData;
}

-(void)update
{
    glBindTexture(GL_TEXTURE_2D, _name);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _width, _height, GL_RGBA, GL_UNSIGNED_BYTE, _imageData);
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:@"invalid texture" format:@"glError is %d", glError];
    }
}

-(void)setRepeat:(BOOL)value
{
    _repeat = value;
    glBindTexture(GL_TEXTURE_2D, _name);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _repeat ? GL_REPEAT : GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _repeat ? GL_REPEAT : GL_CLAMP_TO_EDGE);
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:@"invalid texture" format:@"glError is %d", glError];
    }
}

@end
