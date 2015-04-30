//
// Created by Jonathan Slater on 30/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@protocol DisplayObject<NSObject>

-(void)renderWithMvpMatrix:(GLKMatrix4)mvpMatrix alpha:(float)alpha;

@end
