//
//  vector3.h
//  mset
//
//  Created by Jonathan Slater on 19/07/2016.
//  Copyright © 2016 Jonathan Slater. All rights reserved.
//

#ifndef vector3_h
#define vector3_h

#include <math.h>

union _Vector3 {
    struct {
        double x, y, z;
    };
    struct {
        double r, g, b;
    };
    struct {
        double s, t, p;
    };
    double v[3];
};
typedef union _Vector3 Vector3;

static inline Vector3 vector3Make(double x, double y, double z) {
    Vector3 v = {x, y, z};
    return v;
}

static inline double vector3Length(Vector3 vector) {
    return sqrt(vector.v[0] * vector.v[0] + vector.v[1] * vector.v[1] + vector.v[2] * vector.v[2]);
}

static inline Vector3 vector3Normalize(Vector3 vector) {
    double scale = 1.0f / vector3Length(vector);
    Vector3 v = {vector.v[0] * scale, vector.v[1] * scale, vector.v[2] * scale};
    return v;
}

#endif /* vector3_h */
