#include "CQ.h"
#pragma STDC FENV_ACCESS ON
/* cq-z75a (CR rules 9, 20, 24): musl's FORCE_EVAL / volatile temporaries under a quantum predicate, the shapes
   of erf, erfc, exp10, tgamma and tgammaf (specialcase, pow): a volatile local after llvm.lifetime.start
   written with a quantum value and read back, and a volatile local that is only written (the sink). Each
   store into the undef cell is the plain store; no select reads a handle no store wrote. */
double f_value(double x) {
  double y = x;
  if (x < 1.0) {
    volatile double v = x * 3.0;
    y = v * 0.5;
  }
  return y;
}
double f_sink(double x) {
  double y = x;
  if (x < 1.0) {
    volatile double t = 0x1p-1022;
    double u = t * 0x1p-1022;
    volatile double s;
    s = u;
    y = x + u;
  }
  return y;
}
double e_value(double a) { cq_theta(&a, 0.3); return cq_measure(f_value(a)); }
double e_sink(double a) { cq_theta(&a, 0.3); return cq_measure(f_sink(a)); }
