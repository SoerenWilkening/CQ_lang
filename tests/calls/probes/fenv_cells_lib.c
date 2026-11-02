/* tests/calls probe (cq-4e6m): callees compiled under FENV_ACCESS ON (strict ops: 82's ABI). */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) void sc(double x, double *y) { y[0] = x * 3.0; y[1] = x - 1.0; }
__attribute__((noinline)) int sc2(double x, double *y) { int n = 0; *y = x * 2.0; if (*y > 1.0) { n = 1; *y = x - 1.0; } return n; }
__attribute__((noinline)) void addto(int *p, int *q, double z) { *p += *q + (z > 0.0); }
