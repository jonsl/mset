//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

typedef NS_ENUM(NSInteger, RenderMode) {
    RenderModeSinglePrecision = 1,
    RenderModeDoublePrecision
};

@protocol Fractal<NSObject>

@required

-(instancetype)initWithWidth:(CGFloat)width height:(CGFloat)height;

-(void)renderWithMvpMatrix:(GLKMatrix4)mvpMatrix
            fragmentShader:(NSString*)fragmentShader
                renderMode:(RenderMode)renderMode
                iterations:(GLint)iterations
                    radius:(double)radius
              frameCounter:(NSInteger)frameCounter;

@property (nonatomic, strong) ComplexPlane* complexPlane;

@end
