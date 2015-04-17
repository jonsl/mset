//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


static NSString* SetTypeKey = @"FractalType";
static NSString* ExecutionUnitsKey = @"ExecutionUnits";
static NSString* ExecutionStrategyKey = @"ExecutionStrategy";
static NSString* RenderStrategyKey = @"RenderStrategy";

@implementation Configuration {
}

+(instancetype)sharedConfiguration {
    static Configuration* configuration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        configuration = [[self alloc] initWithSetType:MandelbrotSet
                                       executionUnits:[[NSProcessInfo processInfo] activeProcessorCount]
                                    executionStrategy:ThreadExecution
                                       renderStrategy:TileRender];
    });
    return configuration;
}

-(instancetype)initWithSetType:(FractalType)setType
                executionUnits:(NSUInteger)executionUnits
             executionStrategy:(ExecutionStrategy)executionStrategy
                renderStrategy:(RenderStrategy)renderStrategy {
    if ((self = [super init])) {
        self.setType = setType;
        self.executionUnits = executionUnits;
        self.executionStrategy = executionStrategy;
        self.renderStrategy = renderStrategy;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:@(self.setType) forKey:SetTypeKey];
    [encoder encodeObject:@(self.executionUnits) forKey:ExecutionUnitsKey];
    [encoder encodeObject:@(self.executionStrategy) forKey:ExecutionStrategyKey];
    [encoder encodeObject:@(self.renderStrategy) forKey:RenderStrategyKey];
}

-(id)initWithCoder:(NSCoder*)decoder {
    FractalType setType = (FractalType)[[decoder decodeObjectForKey:SetTypeKey] integerValue];
    NSUInteger executionUnits = (NSUInteger)[[decoder decodeObjectForKey:ExecutionUnitsKey] integerValue];
    ExecutionStrategy executionStrategy = (ExecutionStrategy)[[decoder decodeObjectForKey:ExecutionStrategyKey] integerValue];
    RenderStrategy renderStrategy = (RenderStrategy)[[decoder decodeObjectForKey:RenderStrategyKey] integerValue];
    return [self initWithSetType:setType
                  executionUnits:executionUnits
               executionStrategy:executionStrategy
                  renderStrategy:renderStrategy];
}

@end
