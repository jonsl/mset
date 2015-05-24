//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"
#import "Util.h"
#import <pthread.h>


static NSInteger const MaxIterations = 256;
static float const CanvasTextureSize = 1024.f;

typedef struct {
    NSUInteger _width, _height;
    NSInteger _escapeRadius;
    NSUInteger _maxIterations;
    unsigned char* _rgba;
    ColourLookup _colourTable;
    NSUInteger _startY, _strideY;
    CPPoint _cOrigin, _crMaxiMin, _crMiniMax;
} ExecutionContext;

static Vertex* baseShaderQuad;

@interface MandelbrotSet()

@property (nonatomic, strong) Quad* canvasQuad;
@property (nonatomic, strong) Texture* paletteTexture;
@property (nonatomic, strong) RenderingState* directRenderingState;
@property (nonatomic, strong) NSString* directRenderingVertexShader;
@property (nonatomic, strong) NSString* directRenderingFragmentShader;

@end

@implementation MandelbrotSet

@synthesize complexPlane = _complexPlane;

+(MandelbrotSet*)mandelbrotSet {
    return [[MandelbrotSet alloc] init];
}

-(instancetype)init {
    if ((self = [super init])) {
        Texture* canvasTexture = [Texture textureWithWidth:CanvasTextureSize height:CanvasTextureSize scale:1];
        self.canvasQuad = [Quad quadWithTexture:canvasTexture width:canvasTexture.width height:canvasTexture.height];

        baseShaderQuad = malloc(sizeof(Vertex) * 4);

        baseShaderQuad[0].x.x = -1.f;
        baseShaderQuad[0].x.y = -1.f;
        baseShaderQuad[0].uv.x = 0.f;
        baseShaderQuad[0].uv.y = 0.f;
        baseShaderQuad[0].colour.r = 0xff;
        baseShaderQuad[0].colour.g = 0xff;
        baseShaderQuad[0].colour.b = 0xff;
        baseShaderQuad[0].colour.a = 0xff;

        baseShaderQuad[1].x.x = -1.f;
        baseShaderQuad[1].x.y = +1.f;
        baseShaderQuad[1].uv.x = 0.f;
        baseShaderQuad[1].uv.y = 1.f;
        baseShaderQuad[1].colour.r = 0xff;
        baseShaderQuad[1].colour.g = 0xff;
        baseShaderQuad[1].colour.b = 0xff;
        baseShaderQuad[1].colour.a = 0xff;

        baseShaderQuad[2].x.x = +1.f;
        baseShaderQuad[2].x.y = -1.f;
        baseShaderQuad[2].uv.x = 1.f;
        baseShaderQuad[2].uv.y = 0.f;
        baseShaderQuad[2].colour.r = 0xff;
        baseShaderQuad[2].colour.g = 0xff;
        baseShaderQuad[2].colour.b = 0xff;
        baseShaderQuad[2].colour.a = 0xff;

        baseShaderQuad[3].x.x = +1.f;
        baseShaderQuad[3].x.y = +1.f;
        baseShaderQuad[3].uv.x = 1.f;
        baseShaderQuad[3].uv.y = 1.f;
        baseShaderQuad[3].colour.r = 0xff;
        baseShaderQuad[3].colour.g = 0xff;
        baseShaderQuad[3].colour.b = 0xff;
        baseShaderQuad[3].colour.a = 0xff;
    }
    return self;
}

-(void)dealloc {
    free(baseShaderQuad);
    baseShaderQuad = 0;
}

-(void)setComplexPlane:(ComplexPlane*)complexPlane {
    _complexPlane = complexPlane;

    [self updateQuad];
}

-(void)updateQuad {
    baseShaderQuad[0].uv.x = (CGFloat)_complexPlane.origin.r;
    baseShaderQuad[0].uv.y = (CGFloat)_complexPlane.origin.i;

    baseShaderQuad[1].uv.x = (CGFloat)_complexPlane.rMiniMax.r;
    baseShaderQuad[1].uv.y = (CGFloat)_complexPlane.rMiniMax.i;

    baseShaderQuad[2].uv.x = (CGFloat)_complexPlane.rMaxiMin.r;
    baseShaderQuad[2].uv.y = (CGFloat)_complexPlane.rMaxiMin.i;

    baseShaderQuad[3].uv.x = (CGFloat)(_complexPlane.rMiniMax.r + _complexPlane.rMaxiMin.r - _complexPlane.origin.r);
    baseShaderQuad[3].uv.y = (CGFloat)(_complexPlane.rMiniMax.i + _complexPlane.rMaxiMin.i - _complexPlane.origin.i);
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
        return (float)(N + 1 - logl(logl(sqrt(Zrsqr + Zisqr))) / logl(escapeRadius));
    } else {
        return (float)N;
    }
}


void* renderThread(void* arg) {
    ExecutionContext* const ec = (ExecutionContext* const)arg;
    size_t const colourEntries = ec->_colourTable.size / 3;
    Real const fX = 1.0 / ec->_width;
    Real const fY = 1.0 / ec->_height;
    for (NSUInteger y = ec->_startY; y < ec->_height; y += ec->_strideY) {
        for (NSUInteger x = 0; x < ec->_width; ++x) {
            Real const dX = x * fX;
            Real const dY = y * fY;
            Real cR = ec->_cOrigin.r + dX * (ec->_crMaxiMin.r - ec->_cOrigin.r) + dY * (ec->_crMiniMax.r - ec->_cOrigin.r);
            Real cI = ec->_cOrigin.i + dY * (ec->_crMiniMax.i - ec->_cOrigin.i) + dX * (ec->_crMaxiMin.i - ec->_cOrigin.i);
            float iterations = calculatePoint(cR, cI, ec->_escapeRadius, ec->_maxIterations, true);
            NSInteger colorIndex = (NSInteger)(iterations / ec->_maxIterations * colourEntries);
//            if (colorIndex >= colourEntries) {
//                colorIndex = colourEntries-1;
//            }
//            if (colorIndex < 0) {
//                colorIndex = 0;
//            }
            NSUInteger ppos = 4 * (ec->_width * y + x);
            if ((NSInteger)iterations == ec->_maxIterations) {
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

-(void)compute:(unsigned char*)rgba
         width:(NSUInteger)width
        height:(NSUInteger)height
  escapeRadius:(NSInteger)escapeRadius
 maxIterations:(NSUInteger)maxIterations
     colourMap:(NSObject<ColourMapping>*)colourMap
executionUnits:(NSUInteger)executionUnits
    updateDraw:(void (^)())updateDraw {
    if (_complexPlane == nil) {
        [NSException raise:ExceptionLogicError format:@"invalid fractalDescriptor"];
    }

    pthread_t* threads = calloc(executionUnits, sizeof(pthread_t));
    ExecutionContext* contexts = calloc(executionUnits, sizeof(ExecutionContext));

    for (NSUInteger i = 0; i < executionUnits; i++) {
        memset(&contexts[i], 0, sizeof(ExecutionContext));
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
        int threadError = pthread_create(&threads[i], NULL, &renderThread, (void*)&contexts[i]);
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

-(NSString*)vertexShader {
    NSMutableString* source = [NSMutableString string];

    [source appendLine:@"attribute vec2 aPosition;"];
    [source appendLine:@"attribute vec2 aTexCoords;"];
    [source appendLine:@"varying highp vec2 vTexCoords;"];

    [source appendLine:@"void main() {"];
    [source appendLine:@"  gl_Position = vec4(aPosition, 0., 1.);"];
    [source appendLine:@"  vTexCoords  = aTexCoords;"];
    [source appendString:@"}"];

    return source;
}

-(NSString*)fragmentShader {
    NSMutableString* source = [NSMutableString string];

    [source appendLine:@"uniform highp vec2 uCenter;"];
    [source appendLine:@"uniform highp float uScale;"];
    [source appendLine:@"uniform highp float uRotation;"];
    [source appendLine:@"uniform highp mat4 uMvpMatrix;"];
//    [source appendLine:@"uniform lowp sampler2D uTexture;"];
    [source appendLine:@"uniform int uMaxIterations;"];
    [source appendLine:@"varying highp vec2 vTexCoords;"];
    [source appendLine:@"  const mediump vec3 colourPhase = vec3(5,7,11)/80.0;"];
    [source appendLine:@"  const mediump vec3 colourPhaseStart = vec3(1);"];

    [source appendLine:@"highp float mandel() {"];
//    [source appendLine:@"  highp vec2 c;"];
    [source appendLine:@"  highp vec2 c = vTexCoords;"];
//    [source appendLine:@"  c = (vTexCoords -0.5) * uScale - uCenter;"];
//    [source appendLine:@"  c = vTexCoords;"];
//    [source appendLine:@"  c.y /= 1.33333;"];
//    [source appendLine:@"  r = c * cos(uRotation) + vec2(1,-1) * sin(uRotation) * c.yx;"];
//    [source appendLine:@"  r = (vec4(c.xy,0.,1.) * uMvpMatrix).xy;"];
//    [source appendLine:@"  r = vTexCoords;"];
    [source appendLine:@"  highp vec2 z = c;"];
    [source appendLine:@"  int n;"];
    [source appendLine:@"  for(n=0; n<uMaxIterations; n++) {"];
//    [source appendLine:@"    z = vec2( z.x*z.x - z.y*z.y, 2.*z.x*z.y ) + c;"];
//    [source appendLine:@"    if( dot(z,z)>4. ) {"];
//    [source appendLine:@"      return(float(n) + 1. - log(log(length(vec2(z.x, z.x))))/log(2.));"];
//    [source appendLine:@"    }"];
    [source appendLine:@"    highp float x = (z.x * z.x - z.y * z.y) + c.x;"];
    [source appendLine:@"    highp float y = (z.y * z.x + z.x * z.y) + c.y;"];
    [source appendLine:@"    if (dot(x,x)+dot(y,y) > 4.) break;"];
    [source appendLine:@"    z.x = x;"];
    [source appendLine:@"    z.y = y;"];
    [source appendLine:@"  }"];
    [source appendLine:@"  return float(n);"];
    [source appendLine:@"}"];
    [source appendLine:@"void main() {"];
    [source appendLine:@"  highp float n = mandel();"];
//    [source appendLine:@"  lowp vec2 uv;"];
//    [source appendLine:@"  uv.x = (float(N) - log2(log2(sqrt(z.x * z.x - z.y * z.y))) / log(2.0)) / float(uMaxIterations);"];
//    [source appendLine:@"  uv.x = pow(sin(colourPhase.xyz * float(iterations) + colourPhaseStart)*.5+.5,vec3(1.5));"];
//    [source appendLine:@"  uv.x = (N == uMaxIterations ? 0.0 : float(N)) / float(uMaxIterations);"];
//    [source appendLine:@"  uv.y = 0.0;"];
    [source appendLine:@"  gl_FragColor = vec4(pow(sin(colourPhase.xyz * n + colourPhaseStart)*.5+.5,vec3(1.5)), 1.);"];
//    [source appendLine:@"  gl_FragColor = vec4((-cos(0.025*n)+1.0)/2.0, (-cos(0.08*n)+1.0)/2.0, (-cos(0.12*n)+1.0)/2.0, 1.);"];
//    [source appendLine:@"  gl_FragColor = texture2D(uTexture, uv);"];
    [source appendString:@"}"];

    return source;
}

#pragma mark Fractal

-(void)updateWithComplexPlane:(ComplexPlane*)complexPlane screenSize:(CGSize)screenSize {
    self.complexPlane = complexPlane;
//    NSLog(@"recomputing with complex plane origin(%lf,%lf), rMiniMax(%lf,%lf), rMiniMax(%lf,%lf)", _complexPlane.origin.r, _complexPlane.origin.i,
//            _complexPlane.rMaxiMin.r, _complexPlane.rMaxiMin.i, _complexPlane.rMiniMax.r, _complexPlane.rMiniMax.i);

    switch ([Configuration sharedConfiguration].renderStrategy) {
        case CpuRender: {
            PolynomialColourMap* newColourMap = [[PolynomialColourMap alloc] initWithSize:4096];
            [self compute:self.canvasQuad.texture.imageData
                    width:(NSUInteger)screenSize.width
                   height:(NSUInteger)screenSize.height
             escapeRadius:(NSInteger)2
            maxIterations:(NSUInteger)MaxIterations
                    //              colourMap:defaultColourTable
                colourMap:newColourMap
           executionUnits:[Configuration sharedConfiguration].executionUnits
               updateDraw:^() {
                   [self.canvasQuad updateImage];
               }];
            break;
        };
        case GpuRender: {
            break;
        };
    }
}

#pragma mark DisplayObject

-(void)renderWithMvpMatrix:(GLKMatrix4)mvpMatrix alpha:(float)alpha {
    switch ([Configuration sharedConfiguration].renderStrategy) {
        case CpuRender: {
            [self.canvasQuad renderWithMvpMatrix:mvpMatrix alpha:1.f];
            break;
        };
        case GpuRender: {
            if (!self.directRenderingState) {
                self.directRenderingState = [[RenderingState alloc] init];
            }
            if (!self.directRenderingVertexShader) {
                self.directRenderingVertexShader = [self vertexShader];
            }
            if (!self.directRenderingFragmentShader) {
                self.directRenderingFragmentShader = [self fragmentShader];
            }
//            if (!self.paletteTexture) {
//                self.paletteTexture = [Texture textureWithImage:@"pal.png" scale:1.f];
//            }
            self.directRenderingState.texture = nil;//self.paletteTexture;
            self.directRenderingState.mvpMatrix = mvpMatrix;
            self.directRenderingState.alpha = alpha;
            [self.directRenderingState prepareToDrawWithVertexShader:self.directRenderingVertexShader
                                                      fragmentShader:self.directRenderingFragmentShader];
            int uMvpMatrix = [self.directRenderingState.program getTrait:@"uMvpMatrix"];
            if (uMvpMatrix != -1) {
                glUniformMatrix4fv(uMvpMatrix, 1, NO, mvpMatrix.m);
            }
            int uCentre = [self.directRenderingState.program getTrait:@"uCenter"];
            if (uCentre != -1) {
                glUniform2f(uCentre, mvpMatrix.m[12], mvpMatrix.m[13]);
            }
            int uScale = [self.directRenderingState.program getTrait:@"uScale"];
            if (uScale != -1) {
                glUniform1f(uScale, 4);
            }
            int uRotation = [self.directRenderingState.program getTrait:@"uRotation"];
            if (uRotation != -1) {
                glUniform1f(uRotation, 0);
            }
            int uMaxIterations = [self.directRenderingState.program getTrait:@"uMaxIterations"];
            if (uMaxIterations != -1) {
                glUniform1i(uMaxIterations, MaxIterations);
            }
            int aPosition = [self.directRenderingState.program getTrait:@"aPosition"];
            if (aPosition != -1) {
                glEnableVertexAttribArray((GLuint)aPosition);
                glVertexAttribPointer((GLuint)aPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)baseShaderQuad + (offsetof(Vertex, x)));
            }
            int aTexture = [self.directRenderingState.program getTrait:@"aTexCoords"];
            if (aTexture != -1) {
                glEnableVertexAttribArray((GLuint)aTexture);
                glVertexAttribPointer((GLuint)aTexture, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)baseShaderQuad + (offsetof(Vertex, uv)));
            }
            // Draw
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            break;
        };
    }
}

@end
