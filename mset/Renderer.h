//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@interface Renderer : NSObject

+(instancetype)rendererWithWidth:(float)width height:(float)height;
-(void)render:(NSObject<Fractal>*)fractal;

@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;

@end
