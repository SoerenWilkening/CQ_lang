/* tests/calls probe (cq-4e6m): a caller with the fenv state that is not on the lowered chain. */
#include <fenv.h>
double third(double x);
#pragma STDC FENV_ACCESS ON
double other(double a) { fesetround(FE_UPWARD); double r = third(a); fesetround(FE_TONEAREST); return r; }
