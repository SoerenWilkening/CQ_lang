/* Owner ruling 2026-11-12 cq-dbtpi: a deferred fwide whose result the program never reads excludes nothing. */
#include <stdio.h>
#include <wchar.h>
#include "CQ.h"
int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    fwide(stdout, x);
    return cq_measure(x + 5);
}
