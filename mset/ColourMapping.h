//
// Created by Jonathan Slater on 20/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

@protocol ColourMapping<NSObject>

@required
@property (nonatomic, readonly) unsigned char* rgb;
@property (nonatomic, readonly) NSUInteger size;

@end
