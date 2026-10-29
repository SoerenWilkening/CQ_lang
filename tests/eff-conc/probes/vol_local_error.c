#include "CQ.h"
/* 32's shape: an unobservable volatile slot holding a quantum value. eff-conc routes it as the plain
   slot access (rule 24); mem-slots does not forward a volatile store to its load yet (cq-r4cz). Update this test when it does: move it back into conc.c as a checked entry. */
int vol_local_error(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    volatile int tmp = x + c; /* unobservable volatile slot holding a quantum value */
    return cq_measure(tmp * 2);
}

