//
//  vector4.h
//  mset
//
//  Created by Jonathan Slater on 19/07/2016.
//  Copyright © 2016 Jonathan Slater. All rights reserved.
//

#ifndef vector4_h
#define vector4_h

union _Vector4 {
    struct {
        double x, y, z, w;
    };
    struct {
        double r, g, b, a;
    };
    struct {
        double s, t, p, q;
    };
    double v[4];
} __attribute__((aligned(16)));
typedef union _Vector4 Vector4;

static inline Vector4 vector4Make(double x, double y, double z, double w) {
    Vector4 v = {x, y, z, w};
    return v;
}

#endif /* vector4_h */
