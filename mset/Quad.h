//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface Quad : NSObject

+(instancetype)quadWithWidth:(float)width height:(float)height;
+(instancetype)quadWithColour:(unsigned char)colour width:(float)width height:(float)height;
+(instancetype)quadWithTexture:(Texture*)texture width:(float)width height:(float)height;
-(void)updateImage;
-(void)renderWithMvpMatrix:(GLKMatrix4)mvpMatrix alpha:(float)alpha;
-(Vertex*)vertex:(NSInteger)index;

@property (nonatomic) Vertex* vertexData;
@property (nonatomic, strong) Texture* texture;
@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;
@property (nonatomic, assign) CGPoint position;

@end
