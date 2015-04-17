//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface Quad : NSObject

+(Quad*)quadWithPositionLeft:(float)top left:(float)left;

@property (nonatomic, strong) Texture* texture;

@end
