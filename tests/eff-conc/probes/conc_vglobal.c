#include "CQ.h"
/* Rule 24 over a global (cq-1jvr6, musl's signal: __eintr_valid_flag): an internal global that is only ever stored
   through, volatile, is unobservable (qualifier dropped), but its final value is memory the program leaves, so the
   store under a quantum predicate is rule 20's bus store, not nothing. A dead local's volatile store is nothing. */
static volatile int flag;
int p_vol_global_store(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    if (x > k) flag = 1;
    return cq_measure(x);
}
