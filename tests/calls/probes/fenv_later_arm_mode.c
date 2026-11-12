/* cq-c07bk (rules 9, 23): a quantum branch's then arm calls a body that rounds in the dynamic mode with classical
   arguments; the else arm, linearized after it, makes the mode a rail (fesetround under the predicate). The call in the
   earlier arm reads the classical mode: the own symbol, called as it is. */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) double nx(double x) { return x * 3.0; }
int e(int q0, double t, double x) {
    int q = q0;
    cq_theta(&q, t);
    double r;
    if (q > 5)
        r = nx(x);
    else {
        fesetround(FE_UPWARD);
        r = x / 3.0;
    }
    return cq_measure(r) > 1.0;
}
