#include <fenv.h>
#pragma STDC FENV_ACCESS ON
double fenv_dfl_env(double x0, double th, double c) {
    double x = x0;
    cq_theta(&x, th);
    double y = x * c;                               /* raises into the flags rail */
    fesetenv(FE_DFL_ENV);                           /* mode nearest, flags cleared: the rail is dropped */
    double z = y + c;
    feupdateenv(FE_DFL_ENV);                        /* restore default, then OR the current flags back in */
    int f = fetestexcept(FE_ALL_EXCEPT);
    return cq_measure(z) + (double)cq_measure(f);
}
int fenv_narrow_mask(double x0, double th, double c) {
    double x = x0;
    cq_theta(&x, th);
    double y = x / c;
    fexcept_t saved;
    fegetexceptflag(&saved, FE_INEXACT);            /* save only INEXACT */
    double z = y * c;
    fesetexceptflag(&saved, FE_INEXACT);            /* reinstate only INEXACT: (cur & ~m) | (saved & m) */
    return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(z);
}
int fenv_op_in_arm(double x0, double th, double c, double k) {
    double x = x0;
    cq_theta(&x, th);
    feclearexcept(FE_ALL_EXCEPT);
    double y = x;
    if (x > k)
        y = x * c;                                  /* a constrained op inside a quantum arm */
    return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(y);
}
int fenv_quantum_mode(unsigned m0, double th, double a, double b) {
    unsigned m = m0;
    cq_theta(&m, th);
    int rc = fesetround((int)m);                    /* arbitrary quantum mode: invalid values leave the mode unchanged */
    double s = a + b;
    fesetround(FE_TONEAREST);
    return cq_measure(rc) + (int)cq_measure(s);
}
