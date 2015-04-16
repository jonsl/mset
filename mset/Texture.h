//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

@interface Texture : NSObject

+(instancetype)textureWithWidth:(float)width height:(float)height scale:(float)scale;
-(unsigned char*)rgba;
-(void)update;

@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;
@property (nonatomic, assign) BOOL repeat;

@end
