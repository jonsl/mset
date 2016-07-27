//
// Created by Jonathan Slater on 17/04/15.
// Copyright (c) 2015 Jonathan Slater. All rights reserved.
//

#import "Mset.h"

@interface Quad()

@property (strong, nonatomic) EAGLContext* context;
@property (nonatomic, strong) RenderingState* renderingState;

@end

@implementation Quad {
    Vertex* _vertexData;
    ushort _indexData[6];
    uint _vertexBufferName;
    uint _indexBufferName;
    BOOL _syncRequired;
}

+(instancetype)quadWithWidth:(float)width height:(float)height {
    return [[Quad alloc] initWithColour:0xff width:width height:height];
}

+(instancetype)quadWithColour:(unsigned char)colour width:(float)width height:(float)height {
    return [[Quad alloc] initWithColour:colour width:width height:height];
}

+(instancetype)quadWithTexture:(Texture*)texture width:(float)width height:(float)height {
    return [[Quad alloc] initWithTexture:texture width:width height:height];
}

-(instancetype)initWithColour:(unsigned char)colour width:(float)width height:(float)height {
    if ((self = [super init])) {
        _width = width;
        _height = height;

        self.renderingState = [[RenderingState alloc] init];

        _vertexData = calloc(4, sizeof(Vertex));
        VertexColor rgba = {colour, colour, colour, colour};
        _vertexData[0].colour = rgba;
        _vertexData[1].colour = rgba;
        _vertexData[2].colour = rgba;
        _vertexData[3].colour = rgba;

        _indexData[0] = 0;
        _indexData[1] = 1;
        _indexData[2] = 2;
        _indexData[3] = 1;
        _indexData[4] = 3;
        _indexData[5] = 2;

        self.visible = YES;
    }
    return self;
}

-(instancetype)initWithTexture:(Texture*)texture width:(float)width height:(float)height {
    if ((self = [self initWithColour:0xff width:width height:height])) {
        _vertexData[0].uv.x = 0.f;
        _vertexData[0].uv.y = 0.f;
        _vertexData[1].uv.x = 1.0f;
        _vertexData[1].uv.y = 0.f;
        _vertexData[2].uv.x = 0.f;
        _vertexData[2].uv.y = 1.0f;
        _vertexData[3].uv.x = 1.0f;
        _vertexData[3].uv.y = 1.0f;

        self.texture = texture;
        self.position = CGPointMake(0, 0);
    }
    return self;
}

-(void)dealloc {
    free(_vertexData);
    _vertexData = 0;
}

-(Vertex*)vertex:(NSInteger)index {
    NSAssert(index >= 0 && index < 4, @"invalid index");
    return &_vertexData[index];
}

-(void)setPosition:(CGPoint)position {
    _position = position;
    _vertexData[0].x.x = _position.x;
    _vertexData[0].x.y = _position.y;
    _vertexData[1].x.x = _position.x + _width;
    _vertexData[1].x.y = _position.y;
    _vertexData[2].x.x = _position.x;
    _vertexData[2].x.y = _position.y + _height;
    _vertexData[3].x.x = _position.x + _width;
    _vertexData[3].x.y = _position.y + _height;

    _syncRequired = YES;
}

-(void)setWidth:(float)width {
    _width = width;
    self.position = _position;
}

-(void)setHeight:(float)height {
    _height = height;
    self.position = _position;
}

-(void)setVertexColour:(NSInteger)index colour:(VertexColor)colour {
    NSAssert(index >= 0 && index < 4, @"invalid index");
    _vertexData[index].colour = colour;

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

    NSAssert(_vertexBufferName && _indexBufferName, @"could not create vertex buffers");

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferName);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, (long)sizeof(ushort) * numIndices, _indexData, GL_STATIC_DRAW);

    _syncRequired = YES;
}

-(void)syncBuffers {
    if (!_vertexBufferName) {
        [self createBuffers];
    }
    long numVertices = 4;
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferName);
    glBufferData(GL_ARRAY_BUFFER, (long)sizeof(Vertex) * numVertices, _vertexData, GL_STATIC_DRAW);

    _syncRequired = NO;
#ifdef DEBUG
    GLenum glError = glGetError();
    NSAssert(glError == GL_NO_ERROR, @"glError is %d", glError);
#endif
}

-(void)applyBlendMode:(GLenum)srcFactor dstFactor:(GLenum)dstFactor {
    glEnable(GL_BLEND);
    glBlendFunc(srcFactor, dstFactor);
#ifdef DEBUG
    GLenum glError = glGetError();
    NSAssert(glError == GL_NO_ERROR, @"glError is %d", glError);
#endif
}

-(void)updateImage {
    [self.texture replaceImageData];
}

-(BOOL)hasVisibleArea {
    return _visible;
}

#pragma mark DisplayObject

-(void)renderWithMvpMatrix:(GLKMatrix4)mvpMatrix alpha:(float)alpha {
    if (![self hasVisibleArea]) {
        return;
    }
    if (_syncRequired) {
        [self syncBuffers];
    }
    self.renderingState.texture = self.texture;
    self.renderingState.mvpMatrix = mvpMatrix;
    self.renderingState.alpha = alpha;
    [self.renderingState prepareToDrawWithVertexShader:nil fragmentShader:nil];

    [self applyBlendMode:GL_SRC_ALPHA dstFactor:GL_ONE_MINUS_SRC_ALPHA];

    int aPosition = [self.renderingState.program getTrait:@"a_position"];
    int aColour = [self.renderingState.program getTrait:@"a_colour"];
    int aTexCoords = [self.renderingState.program getTrait:@"a_texCoords"];

    GLuint attribPosition = (GLuint)aPosition;
    GLuint attribColor = (GLuint)aColour;
    GLuint attribTexCoords = (GLuint)aTexCoords;

    glEnableVertexAttribArray(attribPosition);
    glEnableVertexAttribArray(attribColor);
    if (_texture) {
        glEnableVertexAttribArray(attribTexCoords);
    }

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferName);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferName);

    glVertexAttribPointer(attribPosition, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(offsetof(Vertex, x)));
    glVertexAttribPointer(attribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(Vertex), (void*)(offsetof(Vertex, colour)));
    if (_texture) {
        glVertexAttribPointer(attribTexCoords, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(offsetof(Vertex, uv)));
    }

    int numIndices = 6;
    glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_SHORT, 0);
#ifdef DEBUG
    GLenum glError = glGetError();
    NSAssert(glError == GL_NO_ERROR, @"glError is %d", glError);
#endif
}

-(BOOL)checkForExtension:(NSString*)searchName {
    // Create a set containing all extension names.
    // (For better performance, create the set only once and cache it for future use.)
    GLint max = 0;
    glGetIntegerv(GL_NUM_EXTENSIONS, &max);
    NSMutableSet* extensions = [NSMutableSet set];
    for (GLuint i = 0; i < max; i++) {
        [extensions addObject:@( (char*)glGetStringi(GL_EXTENSIONS, i) )];
    }
    return [extensions containsObject:searchName];
}

@end
