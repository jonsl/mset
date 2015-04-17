//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

@interface SetRenderer ()

@property (nonatomic, strong) RendererState* rendererState;
@property (nonatomic, strong) NSMutableArray/*<Quad*>*/* quads;
@property (nonatomic, strong) NSMutableArray/*<Texture*>*/* textures;

@end

@implementation SetRenderer {
    SetType _setType;
    float _width;
    float _height;
}

+(instancetype)setRendererWithType:(SetType)setType numThreads:(NSUInteger)numThreads width:(float)width height:(float)height {
    return [[SetRenderer alloc] initWithSet:setType numThreads:numThreads width:width height:height];
}

-(instancetype)initWithSet:(SetType)setType numThreads:(NSUInteger)numThreads width:(float)width height:(float)height {
    if ((self = [super init])) {
        _setType = setType;
        _width = width;
        _height = height;

        self.rendererState = [RendererState rendererState];

        self.quads = [NSMutableArray arrayWithCapacity:numThreads];


        self.textures = [NSMutableArray arrayWithCapacity:numThreads];
        float textureWidth = width / numThreads;
        float textureHeight = height / numThreads;
        for (int i = 0; i < numThreads; ++i) {
            [self.textures addObject:[Texture textureWithWidth:textureWidth height:textureHeight scale:1]];
        }
    }
    return self;
}

-(void)render {

    for (Texture* texture in self.textures) {
        [texture setPixel:0 rgba:COLOUR_RGBA(0x10, 0x20, 0x30, 0x40)];

//    self.texture.imageData[0] = 0xff;
//    self.texture.imageData[1] = 0xff;
//    self.texture.imageData[2] = 0xff;
//    self.texture.imageData[3] = 0xff;

        [texture replace];

        self.rendererState.mvpMatrix = GLKMatrix4Identity;
        self.rendererState.texture = texture;
        [self.rendererState prepareState];


        // render
    }
}

@end
