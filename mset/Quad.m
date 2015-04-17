//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@implementation Quad {
    Vertex _vertices[4];
    float _left, _top;
}

+(Quad*)quadWithPositionLeft:(float)left top:(float)top {
    return [[Quad alloc] initWithPositionLeft:left top:top];
}

-(instancetype)initWithPositionLeft:(float)left top:(float)top {
    if ((self = [super init])) {

        _left = left;
        _top = top;

        _vertices[0].position.x = _left;
        _vertices[0].position.y = _top;
        _vertices[1].position.y = _top;
        _vertices[2].position.x = _left;


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

    _vertices[1].position.x = _left+texture.width;
    _vertices[2].position.y = _top+texture.height;
    _vertices[3].position.x = _left+texture.width;
    _vertices[3].position.y = _top+texture.height;
}

@end
