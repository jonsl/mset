//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Texture.h"


@implementation Texture {

}

+(instancetype)textureWithWidth:(float)width height:(float)height scale:(float)scale
{
    return [[Texture alloc] initWithWidth:width height:height scale:scale];
}

-(instancetype)initWithWidth:(float)width height:(float)height scale:(float)scale
{
    if ((self = [super init])) {
        // only textures with sidelengths that are powers of 2 support all OpenGL ES features.
        int legalWidth  = [Texture nextPowerOfTwo:width  * scale];
        int legalHeight = [Texture nextPowerOfTwo:height * scale];

        CGColorSpaceRef cgColorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        int bytesPerPixel = 4;

        void *imageData = calloc(legalWidth * legalHeight * bytesPerPixel, 1);
        CGContextRef context = CGBitmapContextCreate(imageData, legalWidth, legalHeight, 8,
                bytesPerPixel * legalWidth, cgColorSpace,
                bitmapInfo);
        CGColorSpaceRelease(cgColorSpace);

        // UIKit referential is upside down - we flip it and apply the scale factor
        CGContextTranslateCTM(context, 0.0f, legalHeight);
        CGContextScaleCTM(context, scale, -scale);

        [self createGlTexture:imageData width:legalWidth height:legalHeight numMipmaps:0];

        CGContextRelease(context);
        free(imageData);
    }
    return self;
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
    GLuint glTexName;
    int bitsPerPixel = 32;

    glGenTextures(1, &glTexName);
    glBindTexture(GL_TEXTURE_2D, glTexName);

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

@end
