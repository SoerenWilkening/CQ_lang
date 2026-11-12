/* tests/calls probe (cq-a9ij3; CR §1.4, rule 23, owner 2026-11-12): a -frounding-math body of round.dynamic ops (no strict
 * op, fenv_rm_modes_lib.c) reached from a FENV_ACCESS caller with a mode other than the literal 0 takes that mode as its one
 * trailing parameter: `_rm` for a classical mode, `_rmq` for a mode rail (a fesetround under a quantum predicate), also with
 * every data argument classical (the all-zero mask names a clone, never the own symbol). Against the C program.
 * Regenerate: clang -O1 fenv_rm_modes.c; clang -O1 -frounding-math fenv_rm_modes_lib.c; llvm-link -S both -o fenv_rm_modes.O1.ll */
#include "CQ.h"
#include <fenv.h>
double third(double x);
#pragma STDC FENV_ACCESS ON
/* a classical mode, classical data: __cq_q_third_0_rm(double, i32) */
int rm_zero(int c0, double t, double x) {
    int c = c0;
    cq_theta(&c, t);
    fesetround(FE_UPWARD);
    double y = third(x);
    fesetround(FE_TONEAREST);
    return cq_measure(c) + (y > 0.3);
}
/* a mode rail, quantum data: __cq_q_third_1_rmq(i32, i32) */
double rmq_q(int c0, double a, double t) {
    int c = c0;
    double x = a;
    cq_theta(&c, t);
    cq_theta(&x, t);
    if (c > 2)
        fesetround(FE_UPWARD);
    double y = third(x);
    return cq_measure(y);
}
/* a mode rail, classical data: __cq_q_third_0_rmq(double, i32), its result a rail */
double rmq_zero(int c0, double x, double t) {
    int c = c0;
    cq_theta(&c, t);
    if (c > 2)
        fesetround(FE_DOWNWARD);
    double y = third(x);
    return cq_measure(y);
}
