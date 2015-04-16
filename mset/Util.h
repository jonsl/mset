//
// Created by Jonathan Slater on 16/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

/*
 * macros
 */
#define COLOUR_RGB(r, g, b) (((uint)(r) << 16) | ((uint)(g) << 8) | (uint)(b))
#define COLOUR_RGBA(r, g, b, a) (((uint)(r) << 24) | ((uint)(g) << 16) | ((uint)(b) << 8) | (uint)(a))

/*
 * types
 */
typedef struct {
    GLKVector2 position;
    GLKVector2 texCoords;
} Vertex;

/*
 * constants
 */
static NSString* const ExceptionLogicError = @"ExceptionLogicError";

/*
 * functions
 */
