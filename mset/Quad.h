//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface Quad : NSObject

+(instancetype)quadWithWidth:(float)width height:(float)height;
-(void)updateImage;
-(void)renderWithAlpha:(float)alpha;

@property (nonatomic, strong) Texture* texture;
@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;
@property (nonatomic, assign) CGPoint textureOffset;

@end
