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
        configuration = [[self alloc] initWithSetType:MandelbrotFractal
                                       executionUnits:[[NSProcessInfo processInfo] activeProcessorCount]
                                    executionStrategy:ThreadExecution];
    });
    return configuration;
}

-(instancetype)initWithSetType:(FractalType)setType
                executionUnits:(NSUInteger)executionUnits
             executionStrategy:(ExecutionStrategy)executionStrategy {
    if ((self = [super init])) {
        self.setType = setType;
        self.executionUnits = executionUnits;
        self.executionStrategy = executionStrategy;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:@(self.setType) forKey:SetTypeKey];
    [encoder encodeObject:@(self.executionUnits) forKey:ExecutionUnitsKey];
    [encoder encodeObject:@(self.executionStrategy) forKey:ExecutionStrategyKey];
}

-(id)initWithCoder:(NSCoder*)decoder {
    FractalType setType = (FractalType)[[decoder decodeObjectForKey:SetTypeKey] integerValue];
    NSUInteger executionUnits = (NSUInteger)[[decoder decodeObjectForKey:ExecutionUnitsKey] integerValue];
    ExecutionStrategy executionStrategy = (ExecutionStrategy)[[decoder decodeObjectForKey:ExecutionStrategyKey] integerValue];
    return [self initWithSetType:setType
                  executionUnits:executionUnits
               executionStrategy:executionStrategy];
}

@end
