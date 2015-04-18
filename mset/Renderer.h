//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface Renderer : NSObject

+(instancetype)rendererWithWidth:(float)width height:(float)height;
-(void)updateImage;
-(void)render;

@property (nonatomic) unsigned char* imageData;
@property (nonatomic) NSUInteger imagewidth;
@property (nonatomic) NSUInteger imageHeight;
@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;
@property (nonatomic, assign) CGPoint textureOffset;

@end
