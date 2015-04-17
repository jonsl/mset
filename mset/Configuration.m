//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


static NSString* ExecutionStrategyKey = @"ExecutionStrategy";

@implementation Configuration {
}

+(instancetype)sharedConfiguration {
    static Configuration* configuration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        configuration = [[self alloc] initWithExecutionStrategy:TileStrategy];
    });
    return configuration;
}

-(instancetype)initWithExecutionStrategy:(ExecutionStrategy)executionStrategy {
    if ((self = [super init])) {
        self.executionStrategy = executionStrategy;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:@(_executionStrategy) forKey:ExecutionStrategyKey];
}

-(id)initWithCoder:(NSCoder*)decoder {
    ExecutionStrategy executionStrategy = [[decoder decodeObjectForKey:ExecutionStrategyKey] shortValue];
    return [self initWithExecutionStrategy:executionStrategy];
}

@end
