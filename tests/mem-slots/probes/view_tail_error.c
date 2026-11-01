#include "CQ.h"
union lw { long double e; unsigned int w[4]; };
unsigned view_tail_error(long double x0, double th, unsigned k) {
    long double x = x0;
    cq_theta(&x, th);
    union lw u;
    u.e = x;
    u.w[2] = k;                /* -O1 splits it at byte 10: a value past the long double, read back from byte 8 (cq-i0fv) */
    return cq_measure(u.w[2]);
}
