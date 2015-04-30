//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

typedef enum FractalType {
    MandelbrotFractal, JuliaFractal
} FractalType;

typedef enum ExecutionStrategy {
    ThreadExecution, DispatchExecution, OperationExecution, ShaderExecution
} ExecutionStrategy;

typedef enum RenderStrategy {
    CpuRender, GpuRender
} RenderStrategy;

@interface Configuration : NSObject<NSCoding>

+(instancetype)sharedConfiguration;

@property (nonatomic, assign) FractalType setType;
@property (nonatomic, assign) NSUInteger executionUnits;
@property (nonatomic, assign) ExecutionStrategy executionStrategy;
@property (nonatomic, assign) RenderStrategy renderStrategy;

@end
