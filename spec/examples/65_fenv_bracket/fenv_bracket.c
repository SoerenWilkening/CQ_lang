#include <fenv.h>
double fenv_bracket(double x0, double th, double c, double k) {
    double x = x0;
    cq_theta(&x, th);
    int oround = fegetround();               /* classical: the ambient mode is round-to-nearest */
    fesetround(FE_TONEAREST);                /* classical, nearest: no-op */
    fenv_t env;
    feholdexcept(&env);                      /* bracket: flags raised inside are unobservable */
    double y = x * c;
    feupdateenv(&env);
    if (y > k)
        feraiseexcept(FE_INEXACT);           /* flag raised under a quantum condition: never tested, deleted */
    fesetround(oround);
    return cq_measure(y);
}
double fenv_tested(double x0, double th, double c, double k) {
    double x = x0;
    cq_theta(&x, th);
    fesetround(FE_UPWARD);                   /* non-nearest mode: the templates round to nearest regardless (user's foot) */
    feclearexcept(FE_INEXACT);               /* the modelled flag set starts clear */
    double y = x * c;
    if (y > k)
        feraiseexcept(FE_INEXACT);           /* flag raised under a quantum condition ... */
    int f = fetestexcept(FE_INEXACT);        /* ... and OBSERVED: f is a quantum value */
    return cq_measure(y) + (double)cq_measure(f);
}
