//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


static NSString* SetTypeKey = @"FractalType";
static NSString* ExecutionUnitsKey = @"ExecutionUnits";
static NSString* ExecutionStrategyKey = @"ExecutionStrategy";

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
        _setType = setType;
        _executionUnits = executionUnits;
        _executionStrategy = executionStrategy;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:@(_setType) forKey:SetTypeKey];
    [encoder encodeObject:@(_executionUnits) forKey:ExecutionUnitsKey];
    [encoder encodeObject:@(_executionStrategy) forKey:ExecutionStrategyKey];
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
