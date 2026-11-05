#include "CQ.h"
/* cq-lyzw (rule 24 with rule 21): an atomic read-modify-write through a fat pointer is the plain load + op
   + store over rule 21's per-object accesses (formerly a stop, cq-z28j). */
int p_rmw_fat(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    int a = 1, b = 2;
    int *p = x > 0 ? &a : &b;
    int old = __atomic_fetch_add(p, 3, __ATOMIC_SEQ_CST);
    return cq_measure(a + b + old);
}
int p_cas_fat(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    int a = 1, b = 2;
    int *p = x > 0 ? &a : &b;
    int want = 2;
    int ok = __atomic_compare_exchange_n(p, &want, 7, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
    return cq_measure(a * 10 + b + ok * 100);
}
