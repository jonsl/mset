//
//  Renderer.h
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Program.h"

@interface Renderer : NSObject

-(instancetype)initWithImageWidth:(CGFloat)width height:(CGFloat)height;
-(void)prepareStateWithTexture:(uint)textureId;

@property (nonatomic, strong) Program* program;
@property (nonatomic, assign) GLKMatrix4 mvpMatrix;
@property (nonatomic, readonly) int uMvpMatrix;

@end
