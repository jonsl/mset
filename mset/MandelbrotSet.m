//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


static Vertex* baseShaderQuad;

@interface MandelbrotSet()

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
        baseShaderQuad = malloc(sizeof(Vertex) * 4);

        baseShaderQuad[0].x.x = -1.f;
        baseShaderQuad[0].x.y = +1.f;
        baseShaderQuad[0].uv.x = 0.f;
        baseShaderQuad[0].uv.y = 0.f;
        baseShaderQuad[0].colour.r = 0xff;
        baseShaderQuad[0].colour.g = 0xff;
        baseShaderQuad[0].colour.b = 0xff;
        baseShaderQuad[0].colour.a = 0xff;

        baseShaderQuad[1].x.x = -1.f;
        baseShaderQuad[1].x.y = -1.f;
        baseShaderQuad[1].uv.x = 0.f;
        baseShaderQuad[1].uv.y = 1.f;
        baseShaderQuad[1].colour.r = 0xff;
        baseShaderQuad[1].colour.g = 0xff;
        baseShaderQuad[1].colour.b = 0xff;
        baseShaderQuad[1].colour.a = 0xff;

        baseShaderQuad[2].x.x = +1.f;
        baseShaderQuad[2].x.y = +1.f;
        baseShaderQuad[2].uv.x = 1.f;
        baseShaderQuad[2].uv.y = 0.f;
        baseShaderQuad[2].colour.r = 0xff;
        baseShaderQuad[2].colour.g = 0xff;
        baseShaderQuad[2].colour.b = 0xff;
        baseShaderQuad[2].colour.a = 0xff;

        baseShaderQuad[3].x.x = +1.f;
        baseShaderQuad[3].x.y = -1.f;
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

    [source appendLine:@"uniform int uMaxIterations;"];
    [source appendLine:@"varying highp vec2 vTexCoords;"];
//    [source appendLine:@"const mediump vec3 colourPhase = vec3(5,7,11)/80.0;"];
//    [source appendLine:@"const mediump vec3 colourPhaseStart = vec3(1);"];

    [source appendLine:@"highp float mandel() {"];
    [source appendLine:@"  highp vec2 c = vTexCoords;"];
    [source appendLine:@"  highp vec2 z = c;"];
    [source appendLine:@"  highp float l = 0.;"];
    [source appendLine:@"  for(int n=0; n<uMaxIterations; n++) {"];
    [source appendLine:@"    z = vec2( z.x*z.x - z.y*z.y, 2.*z.x*z.y ) + c;"];
    [source appendLine:@"    if( dot(z,z)>(256.*256.) ) {"];
    [source appendLine:@"      return l - log2(log2(dot(z, z))) + 4.;"];
    [source appendLine:@"    }"];
    [source appendLine:@"    l += 1.;"];
    [source appendLine:@"  }"];
    [source appendLine:@"  return 0.;"];
    [source appendLine:@"}"];

    [source appendLine:@"void main() {"];
    [source appendLine:@"  highp float n = mandel();"];
//    [source appendLine:@"  gl_FragColor = vec4(pow(sin(colourPhase.xyz * n + colourPhaseStart)*.5+.5,vec3(1.5)), 1.);"];
    [source appendLine:@"  gl_FragColor = vec4((-cos(0.025*n)+1.0)/2.0, (-cos(0.08*n)+1.0)/2.0, (-cos(0.12*n)+1.0)/2.0, 1.);"];
    [source appendString:@"}"];

    return source;
}

#pragma mark Fractal

-(void)updateWithComplexPlane:(ComplexPlane*)complexPlane screenSize:(CGSize)screenSize {
    self.complexPlane = complexPlane;
}

#pragma mark DisplayObject

-(void)renderWithMaxIterations:(NSInteger)maxIterations {


    int range[2], precision;
    glGetShaderPrecisionFormat(GL_FRAGMENT_SHADER, GL_HIGH_INT, range, &precision);
//    double min= floor(log2(range[0]));
//    double max= floor(log2(range[1]));
    NSLog(@"min: %f, max: %f", pow(2, range[0]), pow(2, range[1]));
    
    NSInteger sizeof_double = sizeof(double);



    if (!self.directRenderingState) {
        self.directRenderingState = [[RenderingState alloc] init];
    }
    if (!self.directRenderingVertexShader) {
        self.directRenderingVertexShader = [self vertexShader];
    }
    if (!self.directRenderingFragmentShader) {
        self.directRenderingFragmentShader = [self fragmentShader];
    }
    self.directRenderingState.texture = nil;
    [self.directRenderingState prepareToDrawWithVertexShader:self.directRenderingVertexShader
                                              fragmentShader:self.directRenderingFragmentShader];
    int uMaxIterations = [self.directRenderingState.program getTrait:@"uMaxIterations"];
    if (uMaxIterations != -1) {
        glUniform1i(uMaxIterations, (GLint)maxIterations);
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
}

@end
