//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


static NSString* SetTypeKey = @"FractalType";

@implementation Configuration {
}

+(instancetype)sharedConfiguration {
    static Configuration* configuration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        configuration = [[self alloc] initWithSetType:MandelbrotFractal];
    });
    return configuration;
}

-(instancetype)initWithSetType:(FractalType)setType {
    if ((self = [super init])) {
        _setType = setType;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:@(_setType) forKey:SetTypeKey];
}

-(id)initWithCoder:(NSCoder*)decoder {
    FractalType setType = (FractalType)[[decoder decodeObjectForKey:SetTypeKey] integerValue];
    return [self initWithSetType:setType];
}

@end
