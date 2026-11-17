#include <stdint.h>
int ptrmask_q(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[8] __attribute__((aligned(16))) = {v, v + 1, v + 2, v + 3, v + 4, v + 5, v + 6, v + 7};
    int *p = a + (x & 7);
    int *q = __builtin_align_down(p, 16);
    int *r = __builtin_align_up(p, 16);
    return cq_measure(*q + *r);
}
