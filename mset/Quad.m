//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation Quad {
    Vertex _vertices[4];
}

+(Quad*)quadWithPositionTop:(float)top left:(float)left {
    return [[Quad alloc] initWithPositionTop:top left:left];
}

-(instancetype)initWithPositionTop:(float)top left:(float)left {
    if ((self = [super init])) {
        _vertices[0].texCoords.x = 0.f;
        _vertices[0].texCoords.y = 0.f;
        _vertices[1].texCoords.x = 1.0f;
        _vertices[1].texCoords.y = 0.f;
        _vertices[2].texCoords.x = 0.f;
        _vertices[2].texCoords.y = 1.0f;
        _vertices[3].texCoords.x = 1.0f;
        _vertices[3].texCoords.y = 1.0f;
    }
    return self;
}

-(void)setTexture:(Texture*)texture {
    NSAssert(texture != nil, @"invalid texture");
    _texture = texture;

    _vertices[0].position.x = 0.f;
    _vertices[0].position.y = 0.f;
    _vertices[1].position.x = texture.width;
    _vertices[1].position.y = 0.f;
    _vertices[2].position.x = 0.f;
    _vertices[2].position.y = texture.height;
    _vertices[3].position.x = texture.width;
    _vertices[3].position.y = texture.height;
}

@end
