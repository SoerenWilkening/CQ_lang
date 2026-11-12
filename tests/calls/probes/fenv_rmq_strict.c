/* tests/calls probe (cq-a9ij3; CR §1.4, rule 23, owner 2026-11-12): a FENV_ACCESS body (a strict op: 82's ABI, mode and flags as
 * its last two parameters) reached where the mode is a rail (a fesetround under a quantum predicate in the arm the spine runs
 * first) takes `_rmq`: its mode parameter is the rail's handle and every result is a rail. With classical data the all-zero
 * mask names that clone, never the own symbol (the bead's reproducer: fenv_later_arm_mode with its arms swapped). */
#include "CQ.h"
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) double nx(double x) { return x * 3.0; }
int e(int q0, double t, double x) {
    int q = q0;
    cq_theta(&q, t);
    double r;
    if (q & 1)
        r = nx(x);
    else {
        fesetround(FE_UPWARD);
        r = x / 3.0;
    }
    return cq_measure(r) > 1.0;
}
int eq(int q0, double t, double a) {
    int q = q0;
    double x = a;
    cq_theta(&q, t);
    cq_theta(&x, t);
    if (q > 2)
        fesetround(FE_DOWNWARD);
    double r = nx(x);
    return cq_measure(r) > 1.0;
}
