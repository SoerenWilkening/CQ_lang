#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) double nb(double x) {
    int e = fetestexcept(FE_INEXACT);
    double r = x + 1.0;
    if (!e) feclearexcept(FE_INEXACT);
    return r;
}
#pragma STDC FENV_ACCESS OFF
int e(double x0, double t) { double x = x0; cq_theta(&x, t); return cq_measure(nb(x)) > 0; }
