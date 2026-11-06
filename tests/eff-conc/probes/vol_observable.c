#include "CQ.h"
/* cq-6b2i1: an observable volatile store is a bus store, `_hl`, `_controlled` under a quantum predicate. */
volatile int sink;
void vol_quantum_observable(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    sink = x;   /* a quantum value written where the outside can see it */
}
int p_vol_obs_pred(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    if (x > k) sink = 3;   /* a classical value under a quantum predicate */
    return cq_measure(x);
}
