//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@interface Renderer ()

@property (strong, nonatomic) EAGLContext* context;
@property (nonatomic, strong) RendererState* rendererState;
@property (nonatomic, strong) Texture* texture;
//@property (nonatomic, strong) Quad* quad;
//@property (nonatomic, strong) NSMutableArray/*<Quad*>*/* quads;
//@property (nonatomic, strong) NSMutableArray/*<Texture*>*/* textures;

@end

@implementation Renderer {
    Vertex _vertexData[4];
    ushort _indexData[6];
    uint _vertexBufferName;
    uint _indexBufferName;
    BOOL _requireCompute;
}

+(instancetype)rendererWithWidth:(float)width height:(float)height {
    return [[Renderer alloc] initWithWidth:width height:height];
}

-(instancetype)initWithWidth:(float)width height:(float)height {
    if ((self = [super init])) {
        _width = width;
        _height = height;
        _aspect = _width / _height;

        self.rendererState = [RendererState rendererState];

//        NSUInteger numThreads = [Configuration sharedConfiguration].executionUnits;

        self.texture = [Texture textureWithWidth:_width height:_height scale:1];

//        self.textures = [NSMutableArray arrayWithCapacity:numThreads];
//        float textureWidth = width / (numThreads >> 1);
//        float textureHeight = height / (numThreads >> 1);
//        for (int i = 0; i < numThreads; ++i) {
//            [self.textures addObject:[Texture textureWithWidth:textureWidth height:textureHeight scale:1]];

//        }

        _vertexData[0].position.x = 0;
        _vertexData[0].position.y = 0;
        _vertexData[1].position.x = 0 + self.texture.width;
        _vertexData[1].position.y = 0;
        _vertexData[2].position.x = 0;
        _vertexData[2].position.y = 0 + self.texture.height;
        _vertexData[3].position.x = 0 + self.texture.width;
        _vertexData[3].position.y = 0 + self.texture.height;

        _vertexData[0].texCoords.x = 0.f;
        _vertexData[0].texCoords.y = 0.f;
        _vertexData[1].texCoords.x = 1.0f;
        _vertexData[1].texCoords.y = 0.f;
        _vertexData[2].texCoords.x = 0.f;
        _vertexData[2].texCoords.y = 1.0f;
        _vertexData[3].texCoords.x = 1.0f;
        _vertexData[3].texCoords.y = 1.0f;

        _indexData[0] = 0;
        _indexData[1] = 1;
        _indexData[2] = 2;
        _indexData[3] = 1;
        _indexData[4] = 3;
        _indexData[5] = 2;

        _requireCompute = YES;
    }
    return self;
}

-(void)createBuffers {
    long numVertices = 4;
    long numIndices = 6;

    if (_vertexBufferName) {
        glDeleteBuffers(1, &_vertexBufferName);
    }
    if (_indexBufferName) {
        glDeleteBuffers(1, &_indexBufferName);
    }

    glGenBuffers(1, &_vertexBufferName);
    glGenBuffers(1, &_indexBufferName);

    if (!_vertexBufferName || !_indexBufferName) {
        [NSException raise:ExceptionLogicError format:@"could not create vertex buffers"];
    }

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferName);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, (long) sizeof(ushort) * numIndices, _indexData, GL_STATIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferName);
    glBufferData(GL_ARRAY_BUFFER, (long) sizeof(Vertex) * numVertices, _vertexData, GL_STATIC_DRAW);
#ifdef DEBUG
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
#endif
}

-(void)applyBlendMode:(GLenum)srcFactor dstFactor:(GLenum)dstFactor {
    glEnable(GL_BLEND);
    glBlendFunc(srcFactor, dstFactor);
#ifdef DEBUG
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
#endif
}

-(void)compute:(NSObject<Fractal>*)fractal
          xMin:(double)xMin
          xMax:(double)xMax
          yMin:(double)yMin
          yMax:(double)yMax
 maxIterations:(NSInteger)maxIterations {
    int width = self.texture.width;
    int height = self.texture.height;

    // render
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            double xp = ((double) x / width) * (xMax - xMin) + xMin; /* real point on fractal plane */
            double yp = ((double) y / height) * (yMax - yMin) + yMin;     /* imag - */
            NSInteger iterations = [fractal calculatePoint:xp y:yp escapeRadius:2 maxIterations:maxIterations];
            int ppos = 4 * (width * y + x);
            if (iterations == maxIterations) {
                self.texture.imageData[ppos] = 0;
                self.texture.imageData[ppos + 1] = 0;
                self.texture.imageData[ppos + 2] = 0;
            } else {
                double c = 3.0 * log(iterations) / log(maxIterations - 1.0);
                if (c < 1) {
                    self.texture.imageData[ppos] = (unsigned char) (255.0 * c);
                    self.texture.imageData[ppos + 1] = 0;
                    self.texture.imageData[ppos + 2] = 0;
                } else if (c < 2) {
                    self.texture.imageData[ppos] = 255;
                    self.texture.imageData[ppos + 1] = (unsigned char) (255.0 * (c - 1));
                    self.texture.imageData[ppos + 2] = 0;
                } else {
                    self.texture.imageData[ppos] = 255;
                    self.texture.imageData[ppos + 1] = 255;
                    self.texture.imageData[ppos + 2] = (unsigned char) (255.0 * (c - 2));
                }
            }
            self.texture.imageData[ppos + 3] = 0xff;
        }
    }
    [self.texture replace];
}

-(void)render:(NSObject<Fractal>*)fractal {
    if (!_vertexBufferName) {
        [self createBuffers];
    }

    if (_requireCompute) {

        double centerX = -0.5;
        double centerY = 0;
        double sizeX = 4;
        NSInteger maxIterations = 100;

        [self compute:fractal
                 xMin:centerX - (sizeX / 2)
                 xMax:centerX + (sizeX / 2)
                 yMin:centerY - (sizeX / 2)
                 yMax:centerY + (sizeX / 2)
        maxIterations:maxIterations];
        _requireCompute = NO;
    }

    self.rendererState.texture = self.texture;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, _width, 0, _height, 0.f, 1.f);
    self.rendererState.mvpMatrix = projectionMatrix;
    [self.rendererState prepare];
    [self applyBlendMode:GL_SRC_ALPHA dstFactor:GL_ONE_MINUS_SRC_ALPHA];


    GLuint attribPosition = (GLuint) self.rendererState.aPosition;
    GLuint attribTexCoords = (GLuint) self.rendererState.aTexCoords;

    glEnableVertexAttribArray(attribPosition);
    glEnableVertexAttribArray(attribTexCoords);

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferName);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferName);

    glVertexAttribPointer(attribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
            (void*) (offsetof(Vertex, position)));

    glVertexAttribPointer(attribTexCoords, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex),
            (void*) (offsetof(Vertex, texCoords)));

    int numIndices = 6;
    glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_SHORT, 0);
#ifdef DEBUG
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
#endif
}

-(BOOL)checkForExtension:(NSString*)searchName {
    // Create a set containing all extension names.
    // (For better performance, create the set only once and cache it for future use.)
    GLint max = 0;
    glGetIntegerv(GL_NUM_EXTENSIONS, &max);
    NSMutableSet* extensions = [NSMutableSet set];
    for (GLuint i = 0; i < max; i++) {
        [extensions addObject:@( (char*) glGetStringi(GL_EXTENSIONS, i) )];
    }
    return [extensions containsObject:searchName];
}

@end
