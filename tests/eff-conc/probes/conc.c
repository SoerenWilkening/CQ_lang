#include "CQ.h"
/* eff-conc probes (rule 24): every entry is checked against its own C program. */
static volatile double tiny = 1.0e-300;   /* unobservable: internal, address never escapes */
volatile int obs_counter = 7;             /* observable: external linkage */
static int acell;                         /* classical, accessed atomically */

double p_vol_internal(double x0, double th, double k) {
    double x = x0;
    cq_theta(&x, th);
    double r = x < k ? x * tiny : x - tiny;
    return cq_measure(r);
}

int p_vol_observable(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int seen = obs_counter;   /* observable classical read: stays volatile */
    obs_counter = c;          /* observable classical write, no quantum predicate */
    return cq_measure(x + seen);
}

int p_atomic_classical(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    __atomic_store_n(&acell, c, __ATOMIC_SEQ_CST);
    int v = __atomic_load_n(&acell, __ATOMIC_SEQ_CST);
    return cq_measure(x + v);
}
