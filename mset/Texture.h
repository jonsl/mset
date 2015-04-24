//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

typedef enum TextureFilter {
    NoFilter, LinearFilter,
} TextureFilter;

@interface Texture : NSObject

+(instancetype)textureWithWidth:(float)width height:(float)height scale:(float)scale;
-(void)replace;

@property (nonatomic) unsigned char* imageData;
@property (nonatomic, readonly) NSUInteger width;
@property (nonatomic, readonly) NSUInteger height;
@property (nonatomic, readonly) float scale;
@property (nonatomic, readonly) uint name;
@property (nonatomic, assign) BOOL repeat;
@property (nonatomic, assign) TextureFilter filter;

@end
