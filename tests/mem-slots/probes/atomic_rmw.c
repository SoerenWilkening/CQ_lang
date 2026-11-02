#include "CQ.h"
/* cq-qrvh (CR rule 24, 94): an atomic read-modify-write of a slot cell is its single-thread read-modify-write
   for every atomicrmw operation (xchg, nand, max, umin, fadd, fsub below; uinc_wrap, udec_wrap, fmax, fmin in
   atomic_wrap.ll), unguarded or under a quantum predicate (select(p, new, old) into the cell, rules 9, 20). */
int atomic_xchg(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int cell = x;
    int old = __atomic_exchange_n(&cell, c, __ATOMIC_SEQ_CST);
    return cq_measure(old) + cq_measure(cell);
}
int atomic_ops(int x0, double th, int c, int k) {
    int x = x0;
    cq_theta(&x, th);
    int cell = x;
    int o1 = __atomic_exchange_n(&cell, c ^ x, __ATOMIC_SEQ_CST);
    int o2 = __atomic_fetch_nand(&cell, k, __ATOMIC_SEQ_CST);
    int o3 = __atomic_fetch_max(&cell, k, __ATOMIC_SEQ_CST);
    unsigned u = (unsigned)x, o4 = __atomic_fetch_min(&u, (unsigned)k, __ATOMIC_SEQ_CST);
    int o5 = __atomic_exchange_n(&cell, k, __ATOMIC_SEQ_CST);
    return cq_measure(o1) + cq_measure(o2) + cq_measure(o3) + (int)cq_measure(o4) + cq_measure(o5) +
           cq_measure(cell) + (int)cq_measure(u);
}
double atomic_fp(double x0, double th, double d) {
    double x = x0;
    cq_theta(&x, th);
    double cell = x;
    double o1 = __atomic_fetch_add(&cell, d, __ATOMIC_SEQ_CST);
    double o2 = __atomic_fetch_sub(&cell, x, __ATOMIC_SEQ_CST);
    return cq_measure(o2 + o1) + cq_measure(cell);
}
int atomic_g1(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int cell = x;
    int o = 0;
    if (x > 3)
        o = __atomic_fetch_add(&cell, k, __ATOMIC_SEQ_CST);
    return cq_measure(o) + cq_measure(cell);
}
int atomic_g2(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int cell = x;
    int e = x;
    if (x < 9)
        __atomic_compare_exchange_n(&cell, &e, k, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
    return cq_measure(cell) + cq_measure(e);
}
