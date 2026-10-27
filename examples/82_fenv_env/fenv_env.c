#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) static double scale(double v, double c) { return v * c + c; }
int fenv_env(double x0, double th, double c, double k) {
    double x = x0;
    cq_theta(&x, th);
    double p = x * c;                               /* raises into the flags */
    fenv_t env;
    feholdexcept(&env);                             /* save mode and flags, clear the flags */
    double y = p / c;                               /* raises into the cleared flags */
    int inexact = fetestexcept(FE_INEXACT);
    feupdateenv(&env);                              /* restore, then OR the current flags back in */
    fexcept_t saved;
    fegetexceptflag(&saved, FE_ALL_EXCEPT);
    double z = scale(y, k);                         /* FP work in a callee, under the current environment */
    fesetexceptflag(&saved, FE_ALL_EXCEPT);         /* drop what scale raised */
    fenv_t e2;
    fegetenv(&e2);
    fesetround(FE_UPWARD);
    double w = z * c;
    fesetenv(&e2);                                  /* back to the saved mode and flags */
    return cq_measure(inexact) + (int)cq_measure(w);
}
