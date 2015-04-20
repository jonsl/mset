//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#import <pthread.h>


typedef struct {
    NSUInteger width, height;
    NSInteger escapeRadius;
    NSUInteger maxIterations;
    unsigned char* rgba;
    ColourLookup colourTable;
    NSUInteger startY, strideY;
    Real xMin, xMax, yMin, yMax;
} ExecutionContext;

@implementation MandelbrotSet {
    FractalDescriptor* _fractalDescriptor;
}

+(MandelbrotSet*)mandelbrotSet {
    return [[MandelbrotSet alloc] init];
}

-(instancetype)init {
    if ((self = [super init])) {

    }
    return self;
}

// return: number of iterations to diverge from (x, y), or -1 if convergent
static inline float calculatePoint(Real Cr, Real Ci, NSInteger escapeRadius, NSUInteger maxIterations, bool renormaliseEscape) {
    double Zr = 0;
    double Zi = 0;
    double Zrsqr = Zr * Zr;
    double Zisqr = Zi * Zi;

    NSInteger N = 0;
    NSInteger const ER2 = escapeRadius * escapeRadius;

    while (Zrsqr + Zisqr <= ER2 && N < maxIterations) {
        Zi = (Zr + Zi) * (Zr + Zi) - Zrsqr - Zisqr;
        Zi += Ci;
        Zr = Zrsqr - Zisqr + Cr;
        Zrsqr = Zr * Zr;
        Zisqr = Zi * Zi;
        ++N;
    }
    if (renormaliseEscape && N < maxIterations) {
        return (float)(N + 1 - logl(logl(sqrt(Zrsqr + Zisqr))) / logl(escapeRadius));
    } else {
        return (float) N;
    }
}

void* renderThread(void* arg) {
    ExecutionContext* ec = (ExecutionContext*) arg;
    NSInteger const colourEntries = ec->colourTable.size / 3;
    Real Dr = (ec->xMax - ec->xMin) / (Real)ec->width;
    Real Di = (ec->yMax - ec->yMin) / (Real)ec->height;
    for (NSUInteger y = ec->startY; y < ec->height; y += ec->strideY) {
        for (NSUInteger x = 0; x < ec->width; ++x) {
            Real Cr = ec->xMin + Dr * x;
            Real Ci = ec->yMin + Di * y;
            float iterations = calculatePoint(Cr, Ci, ec->escapeRadius, ec->maxIterations, true);
            NSInteger colorIndex = (NSInteger) (iterations / ec->maxIterations * colourEntries);
//            if (colorIndex >= colourEntries) {
//                colorIndex = colourEntries-1;
//            }
//            if (colorIndex < 0) {
//                colorIndex = 0;
//            }
            NSUInteger ppos = 4 * (ec->width * y + x);
            if ((NSInteger) iterations == ec->maxIterations) {
                ec->rgba[ppos] = 0;
                ec->rgba[ppos + 1] = 0;
                ec->rgba[ppos + 2] = 0;
            } else {
                ec->rgba[ppos] = ec->colourTable.rgb[colorIndex * 3];
                ec->rgba[ppos + 1] = ec->colourTable.rgb[colorIndex * 3 + 1];
                ec->rgba[ppos + 2] = ec->colourTable.rgb[colorIndex * 3 + 2];
            }
            ec->rgba[ppos + 3] = 255;
        }
    }
    return NULL;
}

#pragma mark Fractal

-(void)compute:(unsigned char*)rgba
         width:(NSUInteger)width
        height:(NSUInteger)height
   colourTable:(NSObject <ColourMap>*)colourTable
executionUnits:(NSUInteger)executionUnits
    updateDraw:(DrawBlock)updateDraw {
    if (_fractalDescriptor == nil) {
        [NSException raise:ExceptionLogicError format:@"invalid fractalDescriptor"];
    }

    pthread_t* threads = calloc(executionUnits, sizeof(pthread_t));
    ExecutionContext* contexts = calloc(executionUnits, sizeof(ExecutionContext));

    for (NSUInteger i = 0; i < executionUnits; i++) {
        contexts[i].width = width;
        contexts[i].height = height;
        contexts[i].escapeRadius = _fractalDescriptor.escapeRadius;
        contexts[i].maxIterations = _fractalDescriptor.maxIterations;
        contexts[i].rgba = rgba;
        contexts[i].startY = i;
        contexts[i].strideY = executionUnits;
        contexts[i].xMin = _fractalDescriptor.xMin;
        contexts[i].xMax = _fractalDescriptor.xMax;
        contexts[i].yMin = _fractalDescriptor.yMin;
        contexts[i].yMax = _fractalDescriptor.yMax;
        contexts[i].colourTable.rgb = colourTable.rgb;
        contexts[i].colourTable.size = colourTable.size;
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

-(FractalDescriptor*)fractalDescriptor {
    return _fractalDescriptor;
}

-(void)setFractalDescriptor:(FractalDescriptor*)fractalDescriptor {
    _fractalDescriptor = fractalDescriptor;
}

@end
