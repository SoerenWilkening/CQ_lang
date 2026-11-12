#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) double arms(double x, int c) {
    double r;
    if (c & 1) r = x / 3.0;
    else { fesetround(FE_UPWARD); r = x * 3.0; fesetround(FE_TONEAREST); }
    return r;
}
#pragma STDC FENV_ACCESS OFF
int e(int c0, double x, double t) { int c = c0; cq_theta(&c, t); return cq_measure(arms(x, c)) > 1.0; }
