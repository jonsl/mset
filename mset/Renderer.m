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
}

+(instancetype)rendererWithWidth:(float)width height:(float)height {
    return [[Renderer alloc] initWithWidth:width height:height];
}

-(instancetype)initWithWidth:(float)width height:(float)height {
    if ((self = [super init])) {
        _width = width;
        _height = height;

        self.rendererState = [RendererState rendererState];

//        NSUInteger numThreads = [Configuration sharedConfiguration].executionUnits;

        self.texture = [Texture textureWithWidth:256 height:256 scale:1];

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
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
}

-(void)applyBlendMode:(GLenum)srcFactor dstFactor:(GLenum)dstFactor {
    glEnable(GL_BLEND);
    glBlendFunc(srcFactor, dstFactor);
}

-(void)render:(NSObject <Fractal>*)fractal {
    if (!_vertexBufferName) {
        [self createBuffers];
    }

    self.rendererState.texture = self.texture;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, _width, 0, _height, 0.f, 100.0f);
    self.rendererState.mvpMatrix = projectionMatrix;
    [self.rendererState prepare];
    [self applyBlendMode:GL_SRC_ALPHA dstFactor:GL_ONE_MINUS_SRC_ALPHA];


    // render

    for (int i = 0; i < self.texture.width * self.texture.height; ++i) {
        int base = i << 2;
        self.texture.imageData[base + 0] = 0xff;
        self.texture.imageData[base + 1] = 0x2f;
        self.texture.imageData[base + 2] = 0x00;
        self.texture.imageData[base + 3] = 0x7f;
    }
    [self.texture replace];


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
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        [NSException raise:ExceptionLogicError format:@"glError is %d", glError];
    }
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
