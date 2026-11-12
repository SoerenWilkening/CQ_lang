/* Owner ruling 2026-11-12 cq-dbtpi: ftell under a quantum predicate is deferred; the inputs on which it runs (x odd) read
   its |0> rail and are not compared; the others are compared, and the run is judged on them (Q2 partial exclusion). */
#include <stdio.h>
#include "CQ.h"
int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    long r = 0;
    if (x & 1)
        r = ftell(stdout);
    return cq_measure(x * 3 + (int)r);
}
