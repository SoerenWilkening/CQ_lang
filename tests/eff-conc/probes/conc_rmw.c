#include "CQ.h"
/* cq-py5f (rule 24 on rule 20's QRAM): an atomic read-modify-write of a QRAM cell is the plain
   load + op + store. */
int p_rmw_qram(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int a[4] = {c, c + 1, c + 2, c + 3};
    int old = __atomic_fetch_add(&a[x & 3], 5, __ATOMIC_SEQ_CST);
    int prev = c;
    __atomic_compare_exchange_n(&a[(x + 1) & 3], &prev, 9, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
    return cq_measure(old + a[0] + a[1] + a[2] + a[3]);
}
