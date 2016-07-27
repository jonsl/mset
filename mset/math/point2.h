//
//  point2.h
//  mset
//
//  Created by Jonathan Slater on 20/07/2016.
//  Copyright © 2016 Jonathan Slater. All rights reserved.
//

#ifndef point2_h
#define point2_h

#include <math.h>

union _Point2 {
    struct {
        double x, y;
    };
    struct {
        double r, i;
    };
    double v[2];
};
typedef union _Point2 Point2;

static inline Point2 point2Make(double x, double y) {
    Point2 p;
    p.x = x;
    p.y = y;
    return p;
}

#endif /* point2_h */
