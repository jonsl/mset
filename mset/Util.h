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
    unsigned char r, g, b, a;
} VertexColor;

typedef struct {
    GLKVector2 x;
    GLKVector2 uv;
    VertexColor colour;
} Vertex;

typedef struct {
    double x, y;
} PPoint;

typedef struct {
    unsigned char* rgb;
    size_t size;
} ColourTable;

/*
 * constants
 */
static NSString* const ExceptionLogicError = @"ExceptionLogicError";

/*
 * functions
 */
static unsigned int nextPowerOfTwo(unsigned int value) {
    // REF: https://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2
    unsigned int v = value;
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    return v;
}
