#include "CQ.h"
/* cq-i0fv: a bit-view load reads each byte from the last store that wrote it (review w2a-slots-h1 v5). */
union lv { long double e; unsigned short h[8]; unsigned w[4]; };
unsigned view_pieces(long double x0, double th, unsigned short k) {
    long double x = x0;
    cq_theta(&x, th);
    union lv u;
    u.h[5] = k;                /* byte 10: past the long double the next store writes */
    u.e = x;
    return cq_measure(u.w[2]) >> 16;   /* bytes 8..11: two of the long double, two of h[5] */
}
