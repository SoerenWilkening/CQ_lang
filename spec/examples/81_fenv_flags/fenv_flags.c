#include <fenv.h>
#pragma STDC FENV_ACCESS ON
int fenv_flags(double x0, double th, double c, double k) {
    double x = x0;
    cq_theta(&x, th);
    feclearexcept(FE_ALL_EXCEPT);
    double y = x / c;                               /* raises its exception bits into the flags */
    if (y > k)                                      /* signaling compare: INVALID on a NaN */
        feraiseexcept(FE_OVERFLOW);                 /* raised under a quantum condition */
    int f = fetestexcept(FE_INEXACT | FE_OVERFLOW | FE_INVALID);
    feclearexcept(FE_INEXACT);
    int g = fetestexcept(FE_ALL_EXCEPT);
    return cq_measure(f) + cq_measure(g);
}
