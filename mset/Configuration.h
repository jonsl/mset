//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

typedef enum ExecutionStrategy {
    TileStrategy, LineStrategy, ShaderStrategy
} ExecutionStrategy;

@interface Configuration : NSObject <NSCoding>

+(instancetype)sharedConfiguration;

@property (nonatomic, assign) ExecutionStrategy executionStrategy;

@end
