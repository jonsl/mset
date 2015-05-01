//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


typedef void (^DrawingBlock)(CGContextRef context);

@implementation Texture {
    DrawingBlock _drawingBlock;
}

+(instancetype)textureWithWidth:(float)width height:(float)height scale:(float)scale {
    return [[Texture alloc] initWithWidth:width height:height scale:scale drawingBlock:nil];
}

+(instancetype)textureWithImage:(NSString*)path scale:(float)scale {
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSString *file = [path lastPathComponent];
    NSString* fullPath = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:directory];
    NSData* data = [[NSData alloc] initWithContentsOfFile:fullPath];
    UIImage* image = [[UIImage alloc] initWithData:data];
    return [[Texture alloc] initWithWidth:image.size.width height:image.size.height scale:image.scale drawingBlock:^(CGContextRef context) {
        [image drawAtPoint:CGPointMake(0, 0)];
    }];
}

-(instancetype)initWithWidth:(float)width height:(float)height scale:(float)scale drawingBlock:(DrawingBlock)drawingBlock {
    if ((self = [super init])) {
        // only textures with sidelengths that are powers of 2 support all OpenGL ES features.
        NSUInteger width2 = nextPowerOfTwo(width * scale);
        NSUInteger height2 = nextPowerOfTwo(height * scale);
        NSUInteger const bytesPerPixel = 4;
        _imageData = calloc(width2 * height2 * bytesPerPixel, sizeof(uint8_t));

        CGColorSpaceRef cgColorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;

        CGContextRef context = CGBitmapContextCreate(_imageData, width2, height2, 8,
                bytesPerPixel * width2, cgColorSpace, bitmapInfo);
        CGColorSpaceRelease(cgColorSpace);

        // UIKit referential is upside down - we flip it and apply the scale factor
        CGContextTranslateCTM(context, 0.0f, height2);
        CGContextScaleCTM(context, scale, -scale);
        if (drawingBlock) {
            UIGraphicsPushContext(context);
            drawingBlock(context);
            UIGraphicsPopContext();
        }

        [self createGlTexture:_imageData width:width2 height:height2 numMipmaps:0];

        _width = width2;
        _height = height2;
        _scale = scale;
        _drawingBlock = drawingBlock;

        // invoke setters
        self.repeat = NO;
        self.filter = NoFilter;
    }
    return self;
}

-(void)dealloc {
    glDeleteTextures(1, &_name);
    _name = 0;
    free(_imageData);
    _imageData = 0;
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

    int levelWidth = (int)width;
    int levelHeight = (int)height;
    unsigned char* levelData = (unsigned char*)imgData;
    for (int level = 0; level <= numMipmaps; ++level) {
        int size = levelWidth * levelHeight * bitsPerPixel / 8;
        glTexImage2D(GL_TEXTURE_2D, level, (GLint)glTexFormat, levelWidth, levelHeight,
                0, glTexFormat, glTexType, levelData);
        levelData += size;
        levelWidth /= 2;
        levelHeight /= 2;
    }
    glBindTexture(GL_TEXTURE_2D, 0);
#ifdef DEBUG
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
#endif
}

-(void)replaceImageData {
    glBindTexture(GL_TEXTURE_2D, _name);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLsizei)_width, (GLsizei)_height, GL_RGBA, GL_UNSIGNED_BYTE, _imageData);
#ifdef DEBUG
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
#endif
}

-(void)setRepeat:(BOOL)value {
    _repeat = value;
    glBindTexture(GL_TEXTURE_2D, _name);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _repeat ? GL_REPEAT : GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _repeat ? GL_REPEAT : GL_CLAMP_TO_EDGE);
#ifdef DEBUG
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
#endif
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
#ifdef DEBUG
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
#endif
}

@end
