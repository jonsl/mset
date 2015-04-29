//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#import <pthread.h>


typedef struct {
    NSUInteger _width, _height;
    NSInteger _escapeRadius;
    NSUInteger _maxIterations;
    unsigned char* _rgba;
    ColourLookup _colourTable;
    NSUInteger _startY, _strideY;
    CPPoint _cOrigin, _crMaxiMin, _crMiniMax;
} ExecutionContext;

@implementation MandelbrotSet

@synthesize complexPlane = _complexPlane;

+(MandelbrotSet*)mandelbrotSet {
    return [[MandelbrotSet alloc] init];
}

-(instancetype)init {
    if ((self = [super init])) {

    }
    return self;
}

// return: number of iterations to diverge from (x, y), or -1 if convergent
static inline float calculatePoint(Real cR, Real cI, NSInteger escapeRadius, NSUInteger maxIterations, bool renormaliseEscape) {
    double Zr = 0;
    double Zi = 0;
    double Zrsqr = Zr * Zr;
    double Zisqr = Zi * Zi;

    NSInteger N = 0;
    NSInteger const ER2 = escapeRadius * escapeRadius;

    while (Zrsqr + Zisqr <= ER2 && N < maxIterations) {
        Zi = (Zr + Zi) * (Zr + Zi) - Zrsqr - Zisqr;
        Zi += cI;
        Zr = Zrsqr - Zisqr + cR;
        Zrsqr = Zr * Zr;
        Zisqr = Zi * Zi;
        ++N;
    }
    if (renormaliseEscape && N < maxIterations) {
        return (float) (N + 1 - logl(logl(sqrt(Zrsqr + Zisqr))) / logl(escapeRadius));
    } else {
        return (float) N;
    }
}


void* renderThread(void* arg) {
    ExecutionContext* const ec = (ExecutionContext* const) arg;
    NSInteger const colourEntries = ec->_colourTable.size / 3;
    Real const fX = 1.0 / ec->_width;
    Real const fY = 1.0 / ec->_height;
    for (NSUInteger y = ec->_startY; y < ec->_height; y += ec->_strideY) {
        for (NSUInteger x = 0; x < ec->_width; ++x) {
            Real const dX = x * fX;
            Real const dY = y * fY;
            Real cR = ec->_cOrigin.r + dX * (ec->_crMaxiMin.r - ec->_cOrigin.r) + dY * (ec->_crMiniMax.r - ec->_cOrigin.r);
            Real cI = ec->_cOrigin.i + dY * (ec->_crMiniMax.i - ec->_cOrigin.i) + dX * (ec->_crMaxiMin.i - ec->_cOrigin.i);
            float iterations = calculatePoint(cR, cI, ec->_escapeRadius, ec->_maxIterations, true);
            NSInteger colorIndex = (NSInteger) (iterations / ec->_maxIterations * colourEntries);
//            if (colorIndex >= colourEntries) {
//                colorIndex = colourEntries-1;
//            }
//            if (colorIndex < 0) {
//                colorIndex = 0;
//            }
            NSUInteger ppos = 4 * (ec->_width * y + x);
            if ((NSInteger) iterations == ec->_maxIterations) {
                ec->_rgba[ppos] = 0;
                ec->_rgba[ppos + 1] = 0;
                ec->_rgba[ppos + 2] = 0;
            } else {
                ec->_rgba[ppos] = ec->_colourTable.rgb[colorIndex * 3];
                ec->_rgba[ppos + 1] = ec->_colourTable.rgb[colorIndex * 3 + 1];
                ec->_rgba[ppos + 2] = ec->_colourTable.rgb[colorIndex * 3 + 2];
            }
            ec->_rgba[ppos + 3] = 255;
        }
    }
    return NULL;
}

#pragma mark Fractal

-(void)compute:(unsigned char*)rgba
         width:(NSUInteger)width
        height:(NSUInteger)height
  escapeRadius:(NSInteger)escapeRadius
 maxIterations:(NSUInteger)maxIterations
     colourMap:(NSObject<ColourMapping>*)colourMap
executionUnits:(NSUInteger)executionUnits
    updateDraw:(DrawBlock)updateDraw {
    if (_complexPlane == nil) {
        [NSException raise:ExceptionLogicError format:@"invalid fractalDescriptor"];
    }

    pthread_t* threads = calloc(executionUnits, sizeof(pthread_t));
    ExecutionContext* contexts = calloc(executionUnits, sizeof(ExecutionContext));

    for (NSUInteger i = 0; i < executionUnits; i++) {
        contexts[i]._width = width;
        contexts[i]._height = height;
        contexts[i]._escapeRadius = escapeRadius;
        contexts[i]._maxIterations = maxIterations;
        contexts[i]._rgba = rgba;
        contexts[i]._startY = i;
        contexts[i]._strideY = executionUnits;
        contexts[i]._cOrigin = _complexPlane.origin;
        contexts[i]._crMaxiMin = _complexPlane.rMaxiMin;
        contexts[i]._crMiniMax = _complexPlane.rMiniMax;
        contexts[i]._colourTable.rgb = colourMap.rgb;
        contexts[i]._colourTable.size = colourMap.size;
    }

    NSDate* executeStart = [NSDate date];

    for (NSUInteger i = 0; i < executionUnits; i++) {
        int threadError = pthread_create(&threads[i], NULL, &renderThread, (void*) &contexts[i]);
#ifdef DEBUG
        if (threadError != 0) {
            NSLog(@"pthread_create error: %d", threadError);
        }
#endif
    }
    for (NSInteger i = 0; i < executionUnits; i++) {
        void* status;
        int threadError = pthread_join(threads[i], &status);
#ifdef DEBUG
        if (threadError != 0) {
            NSLog(@"pthread_join error: %d", threadError);
        }
#endif
    }

    NSDate* executeFinish = [NSDate date];
    NSTimeInterval executionTime = [executeFinish timeIntervalSinceDate:executeStart];
    NSLog(@"executionTime = %f", executionTime);

    free(threads);
    free(contexts);

    if (updateDraw) {
        updateDraw();
    }
}

-(NSString*)fragmentShader {
    NSMutableString* source = [NSMutableString string];

    [source appendLine:@"uniform sampler1D tex;"];
    [source appendLine:@"uniform vec2 center;"];
    [source appendLine:@"uniform float scale;"];
    [source appendLine:@"uniform int iter;"];

    [source appendLine:@"void main() {"];

    [source appendLine:@"vec2 z, c;"];
    [source appendLine:@"c.x = 1.3333 * (gl_TexCoord[0].x - 0.5) * scale - center.x;"];
    [source appendLine:@"c.y = (gl_TexCoord[0].y - 0.5) * scale - center.y;"];
    [source appendLine:@"int i;"];
    [source appendLine:@"z = c;"];
    [source appendLine:@"for(i=0; i<iter; i++) {"];
    [source appendLine:@"float x = (z.x * z.x - z.y * z.y) + c.x;"];
    [source appendLine:@"float y = (z.y * z.x + z.x * z.y) + c.y;"];
    [source appendLine:@"if((x * x + y * y) > 4.0) break;"];
    [source appendLine:@"z.x = x;"];
    [source appendLine:@"z.y = y;"];
    [source appendLine:@"}"];
    [source appendLine:@"gl_FragColor = texture1D(tex, (i == iter ? 0.0 : float(i)) / 100.0);"];
    [source appendString:@"}"];

    return source;
}

-(FractalCoordinate)convertCoordinates:(CGPoint)point {
    FractalCoordinate fractalCoordinate;
    fractalCoordinate.x = point.x;
    fractalCoordinate.y = point.y;
    return fractalCoordinate;
}

@end
