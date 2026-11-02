/* tests/calls probe (cq-57ju; CR rule 18 partial measurement, rule 23 default caller): a FENV_ACCESS callee
 * measured from a plain caller: mode 0 and an empty flags rail in, the returned flags rail dead, the measured
 * result copied out before the twin. */
#include "CQ.h"
static __attribute__((noinline)) double scaled(double x, double c) {
#pragma STDC FENV_ACCESS ON
  return x * c + 1.0;
}
double sc_measure(double a, double c) { double x = a; cq_theta(&x, 0.7); return cq_measure(scaled(x, c)); }
double sc_twice(double a, double c) { double x = a; cq_theta(&x, 0.7); double y = scaled(x, c); return cq_measure(y) + cq_measure(y * 2.0); }
