//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"


@interface Quad ()

@property (strong, nonatomic) EAGLContext* context;
@property (nonatomic, strong) RendererState* rendererState;

@end

@implementation Quad {
    Vertex _vertexData[4];
    ushort _indexData[6];
    uint _vertexBufferName;
    uint _indexBufferName;
    BOOL _syncRequired;
}

+(instancetype)quadWithWidth:(float)width height:(float)height {
    return [[Quad alloc] initWithWidth:width height:height];
}

-(instancetype)initWithWidth:(float)width height:(float)height {
    if ((self = [super init])) {
        _width = width;
        _height = height;

        self.rendererState = [RendererState rendererState];

        NSUInteger __unused numThreads = [Configuration sharedConfiguration].executionUnits;

        float size = _width > _height ? _width : _height;
        self.texture = [Texture textureWithWidth:size height:size scale:1];
        self.textureOffset = CGPointMake(-(self.texture.width - _width) / 2, -(self.texture.height - _height) / 2);

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

-(void)setTextureOffset:(CGPoint)textureOffset {
    float xOffset = MAX(-(self.texture.width - _width), MIN(textureOffset.x, 0));
    float yOffset = MAX(-(self.texture.height - _height), MIN(textureOffset.y, 0));
    VertexColor colour = {0xff, 0xff, 0xff, 0xff};
    _vertexData[0].position.x = xOffset;
    _vertexData[0].position.y = yOffset;
    _vertexData[0].colour = colour;
    _vertexData[1].position.x = xOffset + self.texture.width;
    _vertexData[1].position.y = yOffset;
    _vertexData[1].colour = colour;
    _vertexData[2].position.x = xOffset;
    _vertexData[2].position.y = yOffset + self.texture.height;
    _vertexData[2].colour = colour;
    _vertexData[3].position.x = xOffset + self.texture.width;
    _vertexData[3].position.y = yOffset + self.texture.height;
    _vertexData[3].colour = colour;

    _syncRequired = YES;
}

-(void)createBuffers {
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

    _syncRequired = YES;
}

-(void)syncBuffers {
    if (!_vertexBufferName) {
        [self createBuffers];
    }
    long numVertices = 4;
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferName);
    glBufferData(GL_ARRAY_BUFFER, (long) sizeof(Vertex) * numVertices, _vertexData, GL_STATIC_DRAW);

    _syncRequired = NO;
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

-(void)updateImage {
    [self.texture replace];
}

-(void)renderWithAlpha:(float)alpha {
    if (_syncRequired) {
        [self syncBuffers];
    }
    self.rendererState.texture = self.texture;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, _width, 0, _height, 0.f, 1.f);
    self.rendererState.mvpMatrix = projectionMatrix;
    self.rendererState.alpha = alpha;
    [self.rendererState prepare];
    [self applyBlendMode:GL_SRC_ALPHA dstFactor:GL_ONE_MINUS_SRC_ALPHA];

    GLuint attribPosition = (GLuint) self.rendererState.aPosition;
    GLuint attribColor = (GLuint) self.rendererState.aColour;
    GLuint attribTexCoords = (GLuint) self.rendererState.aTexCoords;

    glEnableVertexAttribArray(attribPosition);
    glEnableVertexAttribArray(attribColor);
    if (_texture) {
        glEnableVertexAttribArray(attribTexCoords);
    }

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferName);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferName);

    glVertexAttribPointer(attribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*) (offsetof(Vertex, position)));
    glVertexAttribPointer(attribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(Vertex), (void*) (offsetof(Vertex, colour)));
    if (_texture) {
        glVertexAttribPointer(attribTexCoords, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*) (offsetof(Vertex, texCoords)));
    }

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
