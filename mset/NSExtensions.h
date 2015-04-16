//
//  NSExtensions.h
//  mandelbrot
//
//  Created by Jonathan Slater on 15/04/2015.
//  Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

@implementation NSMutableString(NSExtensions)

- (void)appendLine:(NSString*)line
{
    [self appendFormat:@"%@\n", line];
}

@end
