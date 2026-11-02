#include "CQ.h"
/* tests/loops-classical fatal probe (cq-djnk, review loopscl-h2 p30): fatal_keep_partial with an Ry on x after the
 * loop, before a[3] is measured: the same leak, the same cq::unimplemented. */
unsigned p30(unsigned x0, double th, double th2) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned a[4] = {x & 3, (x >> 2) & 3, (x >> 4) & 3, (x >> 6) & 3};
    for (int i = 0; i < 3; i++)
        if (a[i] > a[i + 1]) { unsigned t = a[i]; a[i] = a[i + 1]; a[i + 1] = t; }
    cq_theta(&x, th2);
    return cq_measure(a[3]) | cq_measure(x) << 8;
}
