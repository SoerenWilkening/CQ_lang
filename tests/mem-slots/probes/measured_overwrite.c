#include "CQ.h"
/* cq-lvx8: a rail stored into a cell that a later store overwrites before any measuring load is garbage,
   not measured (review w2a-slots-h1 e1). */
int measured_overwrite(int k) {
    int x = 0; cq_theta(&x, 0.5);
    int a[2];
    a[0] = x + 1; a[1] = x + 2;
    a[0] = x ^ 5;
    return cq_measure(a[k & 1]);
}
