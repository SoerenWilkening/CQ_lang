/* R (FENV_ACCESS, no FP op of its own) lifts A (no FENV_ACCESS) and then B (FENV_ACCESS); both lift X's raising fmul.
 * R's clone carries the environment through B (rule 23): the carries-env walk once marked X seen under A, a body
 * without the state, and answered false for X when B reached it, so R's clone dropped B's flags (e's fetestexcept). */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) double X(double x) { return x * 0.1; }
__attribute__((noinline)) double B(double x) { return X(x); }
#pragma STDC FENV_ACCESS OFF
__attribute__((noinline)) double A(double x) { return x + X(x * 0.0); }
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) double R(double x) { return B(A(x)); }
int e(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    feclearexcept(FE_ALL_EXCEPT);
    double r = R((double)x);
    return cq_measure(fetestexcept(FE_INEXACT) != 0) + 2 * cq_measure((int)r);
}
