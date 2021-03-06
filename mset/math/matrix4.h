//
//  matrix4.h
//  mset
//
//  Created by Jonathan Slater on 19/07/2016.
//  Copyright © 2016 Jonathan Slater. All rights reserved.
//

#ifndef matrix4_h
#define matrix4_h

#import <math.h>
#import <float.h>
#include <stdbool.h>
#import "vector3.h"
#import "vector4.h"

union _Matrix4 {
    struct {
        double m00, m01, m02, m03;
        double m10, m11, m12, m13;
        double m20, m21, m22, m23;
        double m30, m31, m32, m33;
    };
    double m[16];
} __attribute__((aligned(16)));
typedef union _Matrix4 Matrix4;

extern Matrix4 const g_matrix4Identity;
extern Matrix4 const g_matrix4Zero;

static inline Matrix4 matrix4MakeScale(double sx, double sy, double sz) {
    Matrix4 m = g_matrix4Identity;
    m.m[0] = sx;
    m.m[5] = sy;
    m.m[10] = sz;
    return m;
}

static inline Matrix4 matrix4MakeRotation(double radians, double x, double y, double z) {
    Vector3 v = vector3Normalize(vector3Make(x, y, z));
    double cosr = cos(radians);
    double cosp = 1.0f - cosr;
    double sinr = sin(radians);

    Matrix4 m = {cosr + cosp * v.v[0] * v.v[0],
            cosp * v.v[0] * v.v[1] + v.v[2] * sinr,
            cosp * v.v[0] * v.v[2] - v.v[1] * sinr,
            0.0f,
            cosp * v.v[0] * v.v[1] - v.v[2] * sinr,
            cosr + cosp * v.v[1] * v.v[1],
            cosp * v.v[1] * v.v[2] + v.v[0] * sinr,
            0.0f,
            cosp * v.v[0] * v.v[2] + v.v[1] * sinr,
            cosp * v.v[1] * v.v[2] - v.v[0] * sinr,
            cosr + cosp * v.v[2] * v.v[2],
            0.0f,
            0.0f,
            0.0f,
            0.0f,
            1.0f};

    return m;
}

static inline Matrix4 matrix4Translate(Matrix4 matrix, double tx, double ty, double tz) {
    Matrix4 m = {matrix.m[0], matrix.m[1], matrix.m[2], matrix.m[3],
            matrix.m[4], matrix.m[5], matrix.m[6], matrix.m[7],
            matrix.m[8], matrix.m[9], matrix.m[10], matrix.m[11],
            matrix.m[0] * tx + matrix.m[4] * ty + matrix.m[8] * tz + matrix.m[12],
            matrix.m[1] * tx + matrix.m[5] * ty + matrix.m[9] * tz + matrix.m[13],
            matrix.m[2] * tx + matrix.m[6] * ty + matrix.m[10] * tz + matrix.m[14],
            matrix.m[3] * tx + matrix.m[7] * ty + matrix.m[11] * tz + matrix.m[15]};
    return m;
}

static inline Matrix4 matrix4Scale(Matrix4 matrix, double sx, double sy, double sz) {
    Matrix4 m = {matrix.m[0] * sx, matrix.m[1] * sx, matrix.m[2] * sx, matrix.m[3] * sx,
            matrix.m[4] * sy, matrix.m[5] * sy, matrix.m[6] * sy, matrix.m[7] * sy,
            matrix.m[8] * sz, matrix.m[9] * sz, matrix.m[10] * sz, matrix.m[11] * sz,
            matrix.m[12], matrix.m[13], matrix.m[14], matrix.m[15]};
    return m;
}

static inline Matrix4 matrix4Multiply(Matrix4 matrixLeft, Matrix4 matrixRight) {
    Matrix4 m;

    m.m[0] = matrixLeft.m[0] * matrixRight.m[0] + matrixLeft.m[4] * matrixRight.m[1] + matrixLeft.m[8] * matrixRight.m[2] + matrixLeft.m[12] * matrixRight.m[3];
    m.m[4] = matrixLeft.m[0] * matrixRight.m[4] + matrixLeft.m[4] * matrixRight.m[5] + matrixLeft.m[8] * matrixRight.m[6] + matrixLeft.m[12] * matrixRight.m[7];
    m.m[8] = matrixLeft.m[0] * matrixRight.m[8] + matrixLeft.m[4] * matrixRight.m[9] + matrixLeft.m[8] * matrixRight.m[10] + matrixLeft.m[12] * matrixRight.m[11];
    m.m[12] = matrixLeft.m[0] * matrixRight.m[12] + matrixLeft.m[4] * matrixRight.m[13] + matrixLeft.m[8] * matrixRight.m[14] + matrixLeft.m[12] * matrixRight.m[15];

    m.m[1] = matrixLeft.m[1] * matrixRight.m[0] + matrixLeft.m[5] * matrixRight.m[1] + matrixLeft.m[9] * matrixRight.m[2] + matrixLeft.m[13] * matrixRight.m[3];
    m.m[5] = matrixLeft.m[1] * matrixRight.m[4] + matrixLeft.m[5] * matrixRight.m[5] + matrixLeft.m[9] * matrixRight.m[6] + matrixLeft.m[13] * matrixRight.m[7];
    m.m[9] = matrixLeft.m[1] * matrixRight.m[8] + matrixLeft.m[5] * matrixRight.m[9] + matrixLeft.m[9] * matrixRight.m[10] + matrixLeft.m[13] * matrixRight.m[11];
    m.m[13] = matrixLeft.m[1] * matrixRight.m[12] + matrixLeft.m[5] * matrixRight.m[13] + matrixLeft.m[9] * matrixRight.m[14] + matrixLeft.m[13] * matrixRight.m[15];

    m.m[2] = matrixLeft.m[2] * matrixRight.m[0] + matrixLeft.m[6] * matrixRight.m[1] + matrixLeft.m[10] * matrixRight.m[2] + matrixLeft.m[14] * matrixRight.m[3];
    m.m[6] = matrixLeft.m[2] * matrixRight.m[4] + matrixLeft.m[6] * matrixRight.m[5] + matrixLeft.m[10] * matrixRight.m[6] + matrixLeft.m[14] * matrixRight.m[7];
    m.m[10] = matrixLeft.m[2] * matrixRight.m[8] + matrixLeft.m[6] * matrixRight.m[9] + matrixLeft.m[10] * matrixRight.m[10] + matrixLeft.m[14] * matrixRight.m[11];
    m.m[14] = matrixLeft.m[2] * matrixRight.m[12] + matrixLeft.m[6] * matrixRight.m[13] + matrixLeft.m[10] * matrixRight.m[14] + matrixLeft.m[14] * matrixRight.m[15];

    m.m[3] = matrixLeft.m[3] * matrixRight.m[0] + matrixLeft.m[7] * matrixRight.m[1] + matrixLeft.m[11] * matrixRight.m[2] + matrixLeft.m[15] * matrixRight.m[3];
    m.m[7] = matrixLeft.m[3] * matrixRight.m[4] + matrixLeft.m[7] * matrixRight.m[5] + matrixLeft.m[11] * matrixRight.m[6] + matrixLeft.m[15] * matrixRight.m[7];
    m.m[11] = matrixLeft.m[3] * matrixRight.m[8] + matrixLeft.m[7] * matrixRight.m[9] + matrixLeft.m[11] * matrixRight.m[10] + matrixLeft.m[15] * matrixRight.m[11];
    m.m[15] = matrixLeft.m[3] * matrixRight.m[12] + matrixLeft.m[7] * matrixRight.m[13] + matrixLeft.m[11] * matrixRight.m[14] + matrixLeft.m[15] * matrixRight.m[15];

    return m;
}

static inline Vector4 matrix4MultiplyVector4(Matrix4 matrixLeft, Vector4 vectorRight) {
    Vector4 v = {matrixLeft.m[0] * vectorRight.v[0] + matrixLeft.m[4] * vectorRight.v[1] + matrixLeft.m[8] * vectorRight.v[2] + matrixLeft.m[12] * vectorRight.v[3],
            matrixLeft.m[1] * vectorRight.v[0] + matrixLeft.m[5] * vectorRight.v[1] + matrixLeft.m[9] * vectorRight.v[2] + matrixLeft.m[13] * vectorRight.v[3],
            matrixLeft.m[2] * vectorRight.v[0] + matrixLeft.m[6] * vectorRight.v[1] + matrixLeft.m[10] * vectorRight.v[2] + matrixLeft.m[14] * vectorRight.v[3],
            matrixLeft.m[3] * vectorRight.v[0] + matrixLeft.m[7] * vectorRight.v[1] + matrixLeft.m[11] * vectorRight.v[2] + matrixLeft.m[15] * vectorRight.v[3]};
    return v;
}

static inline Matrix4 matrix4Rotate(Matrix4 matrix, double radians, double x, double y, double z) {
    Matrix4 rm = matrix4MakeRotation(radians, x, y, z);
    return matrix4Multiply(matrix, rm);
}

static inline Matrix4 matrix4Invert(Matrix4 m, bool* isInvertible) {
    double a0 = m.m[0] * m.m[5] - m.m[1] * m.m[4];
    double a1 = m.m[0] * m.m[6] - m.m[2] * m.m[4];
    double a2 = m.m[0] * m.m[7] - m.m[3] * m.m[4];
    double a3 = m.m[1] * m.m[6] - m.m[2] * m.m[5];
    double a4 = m.m[1] * m.m[7] - m.m[3] * m.m[5];
    double a5 = m.m[2] * m.m[7] - m.m[3] * m.m[6];
    double b0 = m.m[8] * m.m[13] - m.m[9] * m.m[12];
    double b1 = m.m[8] * m.m[14] - m.m[10] * m.m[12];
    double b2 = m.m[8] * m.m[15] - m.m[11] * m.m[12];
    double b3 = m.m[9] * m.m[14] - m.m[10] * m.m[13];
    double b4 = m.m[9] * m.m[15] - m.m[11] * m.m[13];
    double b5 = m.m[10] * m.m[15] - m.m[11] * m.m[14];

    double det = a0 * b5 - a1 * b4 + a2 * b3 + a3 * b2 - a4 * b1 + a5 * b0;
    if (fabs(det) > DBL_EPSILON) {
        Matrix4 result;
        result.m[0] = +m.m[5] * b5 - m.m[6] * b4 + m.m[7] * b3;
        result.m[4] = -m.m[4] * b5 + m.m[6] * b2 - m.m[7] * b1;
        result.m[8] = +m.m[4] * b4 - m.m[5] * b2 + m.m[7] * b0;
        result.m[12] = -m.m[4] * b3 + m.m[5] * b1 - m.m[6] * b0;
        result.m[1] = -m.m[1] * b5 + m.m[2] * b4 - m.m[3] * b3;
        result.m[5] = +m.m[0] * b5 - m.m[2] * b2 + m.m[3] * b1;
        result.m[9] = -m.m[0] * b4 + m.m[1] * b2 - m.m[3] * b0;
        result.m[13] = +m.m[0] * b3 - m.m[1] * b1 + m.m[2] * b0;
        result.m[2] = +m.m[13] * a5 - m.m[14] * a4 + m.m[15] * a3;
        result.m[6] = -m.m[12] * a5 + m.m[14] * a2 - m.m[15] * a1;
        result.m[10] = +m.m[12] * a4 - m.m[13] * a2 + m.m[15] * a0;
        result.m[14] = -m.m[12] * a3 + m.m[13] * a1 - m.m[14] * a0;
        result.m[3] = -m.m[9] * a5 + m.m[10] * a4 - m.m[11] * a3;
        result.m[7] = +m.m[8] * a5 - m.m[10] * a2 + m.m[11] * a1;
        result.m[11] = -m.m[8] * a4 + m.m[9] * a2 - m.m[11] * a0;
        result.m[15] = +m.m[8] * a3 - m.m[9] * a1 + m.m[10] * a0;

        double invDet = ((double) 1) / det;
        result.m[0] *= invDet;
        result.m[1] *= invDet;
        result.m[2] *= invDet;
        result.m[3] *= invDet;
        result.m[4] *= invDet;
        result.m[5] *= invDet;
        result.m[6] *= invDet;
        result.m[7] *= invDet;
        result.m[8] *= invDet;
        result.m[9] *= invDet;
        result.m[10] *= invDet;
        result.m[11] *= invDet;
        result.m[12] *= invDet;
        result.m[13] *= invDet;
        result.m[14] *= invDet;
        result.m[15] *= invDet;

        *isInvertible = true;
        return result;
    } else {
        *isInvertible = false;
        return g_matrix4Identity;
    }
}

#endif /* matrix4_h */
