#include "CQ.h"
/* cq-r8-d: two pointer arguments of a declared clone (one snapshot per object): unimplemented. */
extern void ext_sink2(int *p, int *q);
int dp_two(int x0, double tx) {
    int x = x0;
    cq_theta(&x, tx);
    int a[1] = {x + 1}, b[1] = {x + 2};
    ext_sink2(a, b);
    return cq_measure(a[0]);
}
