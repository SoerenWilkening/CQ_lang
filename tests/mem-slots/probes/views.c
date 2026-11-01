#include "CQ.h"
#include <stdio.h>
/* mem-slots probes (cq-w2a-mem-slots): bit views of a value object (63's construction), atomics on a slot
   cell (94's), an internal global across a call that cannot reach it (67's). */
union dw { double d; unsigned int w[2]; };
double p_view_hi(double x0, double th, unsigned k) {
    double x = x0;
    cq_theta(&x, th);
    union dw u;
    u.d = x;
    u.w[1] ^= k;               /* narrower store at byte 4 into the double */
    return cq_measure(u.d);
}
int p_atomic_or(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int cell = x;
    int old = __atomic_fetch_or(&cell, c, __ATOMIC_SEQ_CST);
    return cq_measure(old) + cq_measure(__atomic_load_n(&cell, __ATOMIC_SEQ_CST));
}
static int g;
__attribute__((noinline)) static int other(int v) { printf("%d\n", v); return v * 3; }   /* never reaches g */
int p_global_call(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    g = x + 1;
    int y = other(x);
    return cq_measure(g + y);
}
