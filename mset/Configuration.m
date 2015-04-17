//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


static NSString* RenderStrategyKey = @"RenderStrategy";

@implementation Configuration {
    RenderStrategy _renderStrategy;
}

-(instancetype)initWithRenderStrategy:(RenderStrategy)renderStrategy {
    if ((self = [super init])) {
        _renderStrategy = renderStrategy;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:@(_renderStrategy) forKey:RenderStrategyKey];
}

-(id)initWithCoder:(NSCoder*)decoder {
    RenderStrategy renderStrategy = [[decoder decodeObjectForKey:RenderStrategyKey] shortValue];
    return [self initWithRenderStrategy:renderStrategy];
}

@end
