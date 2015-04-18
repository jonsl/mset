//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#include <complex.h>
#import <pthread.h>


@implementation MandelbrotSet {
    FractalDescriptor* _fractalDescriptor;
}

-(instancetype)init {
    if ((self = [super init])) {

    }
    return self;
}

// return: number of iterations to diverge from (x, y), or -1 if convergent
NSInteger calculatePoint(double x, double y, int escapeRadius, int maxIterations) {
    complex double C, Z;
    int iterations = 0;
    NSInteger const ER2 = escapeRadius * escapeRadius;

    Z = 0 + 0 * I;
    C = x + y * I;

    do {
        Z = Z * Z + C;
        ++iterations;
    } while (
            (creal(Z) * creal(Z) + cimag(Z) * cimag(Z)) <= ER2
                    && iterations < maxIterations
            );
    return iterations;
}

typedef struct {
    NSUInteger width, height;
    NSInteger escapeRadius, maxIterations;
    unsigned char* rgba;
    NSUInteger startX, startY;
    NSUInteger strideX, strideY;
    double xMin, xMax, yMin, yMax;
} ExecutionContext;

void* renderthread(void* arg) {
    ExecutionContext* ec = (ExecutionContext*) arg;
    for (NSUInteger y = ec->startY; y < ec->height; y += ec->strideY) {
        for (NSUInteger x = 0; x < ec->width; ++x) {
            double xp = ((double) x / ec->width) * (ec->xMax - ec->xMin) + ec->xMin; // real point on fractal plane
            double yp = ((double) y / ec->height) * (ec->yMax - ec->yMin) + ec->yMin; // imag point on fractal plane
            NSInteger iterations = calculatePoint(xp, yp, ec->escapeRadius, ec->maxIterations);
            NSUInteger ppos = 4 * (ec->width * y + x);
            if (iterations == ec->maxIterations) {
                ec->rgba[ppos] = 0;
                ec->rgba[ppos + 1] = 0;
                ec->rgba[ppos + 2] = 0;
            } else {
                double c = 3.0 * log(iterations) / log(ec->maxIterations - 1.0);
                if (c < 1) {
                    ec->rgba[ppos] = (unsigned char) (255.0 * c);
                    ec->rgba[ppos + 1] = 0;
                    ec->rgba[ppos + 2] = 0;
                } else if (c < 2) {
                    ec->rgba[ppos] = 255;
                    ec->rgba[ppos + 1] = (unsigned char) (255.0 * (c - 1));
                    ec->rgba[ppos + 2] = 0;
                } else {
                    ec->rgba[ppos] = 255;
                    ec->rgba[ppos + 1] = 255;
                    ec->rgba[ppos + 2] = (unsigned char) (255.0 * (c - 2));
                }
            }
            ec->rgba[ppos + 3] = 0xff;
        }
    }
    return NULL;
}

#pragma mark Fractal

-(void)compute:(unsigned char*)rgba
         width:(NSUInteger)width
        height:(NSUInteger)height
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
        contexts[i].startX = i;
        contexts[i].startY = i;
        contexts[i].strideX = executionUnits;
        contexts[i].strideY = executionUnits;
        contexts[i].xMin = _fractalDescriptor.xMin;
        contexts[i].xMax = _fractalDescriptor.xMax;
        contexts[i].yMin = _fractalDescriptor.yMin;
        contexts[i].yMax = _fractalDescriptor.yMax;
    }
    
    NSDate* executeStart = [NSDate date];
    
    for (NSUInteger i = 0; i < executionUnits; i++) {
        int threadError = pthread_create(&threads[i], NULL, &renderthread, (void*) &contexts[i]);
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

    NSDate *executeFinish = [NSDate date];
    NSTimeInterval executionTime = [executeFinish timeIntervalSinceDate:executeStart];
    NSLog(@"executionTime = %f", executionTime);
    
    free(threads);
    free(contexts);

    if (updateDraw) {
        updateDraw();
    }
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
