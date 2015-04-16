//
//  NSExtensions.m
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "NSExtensions.h"

#pragma mark - NSMutableString

@implementation NSMutableString (SPNSExtensions)

- (void)appendLine:(NSString*)line
{
    [self appendFormat:@"%@\n", line];
}

@end
