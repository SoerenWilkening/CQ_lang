#include "CQ.h"
#include <fenv.h>
#include <string.h>
#pragma STDC FENV_ACCESS ON
/* CR rule 23, Environment objects: an object that is not the confined alloca holds the whole environment in its own
   bytes. No CQ_spec witness (CR §8): the construction choice is at the top of pass/lib/eff/fenv/Fenv.cpp. */
__attribute__((noinline)) static void restore_env(const fenv_t *e) { fesetenv(e); }
__attribute__((noinline)) static void save_env(fenv_t *e) { fegetenv(e); }
/* A pointer formal: saved and restored through a callee. */
int p_env_callee(double x0, double th, double c) {
    double x = x0;
    cq_theta(&x, th);
    fenv_t e;
    double y = x * c;
    save_env(&e);
    feclearexcept(FE_ALL_EXCEPT);
    double z = y / c;
    restore_env(&e);
    return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(z);
}
/* A global object, feholdexcept then feupdateenv. */
fenv_t genv;
int p_env_global(double x0, double th, double c) {
    double x = x0;
    cq_theta(&x, th);
    double y = x * c;
    feholdexcept(&genv);
    double z = y + c;
    feupdateenv(&genv);
    return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(z);
}
/* A fexcept_t in memory. */
static fexcept_t gflag;
int p_flag_global(double x0, double th, double c) {
    double x = x0;
    cq_theta(&x, th);
    double y = x / c;
    fegetexceptflag(&gflag, FE_ALL_EXCEPT);
    feclearexcept(FE_ALL_EXCEPT);
    double z = y * c;
    fesetexceptflag(&gflag, FE_INEXACT);
    return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(z);
}
/* A save under a quantum predicate, a restore after the join. */
int p_env_pred(double x0, double th, double c, double k) {
    double x = x0;
    cq_theta(&x, th);
    fenv_t e;
    save_env(&e);
    double y = x * c;
    if (x > k)
        fegetenv(&e);
    double z = y + c;
    fesetenv(&e);
    return cq_measure(fetestexcept(FE_ALL_EXCEPT)) + (int)cq_measure(z);
}
