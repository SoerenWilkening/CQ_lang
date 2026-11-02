#include "CQ.h"
/* cq-lyzw (rule 24 at f684858, cq-py5f): an observable volatile access with quantum data is a host
   effect: a store is the tape entry volatile_store (address, value) under the predicate, a load the
   host read at its program point, merged. Formerly vol_quantum_observable_error. */
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
