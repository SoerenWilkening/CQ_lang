/* cq-9ea1d: musl fma (bundle IR, renamed qfma) called with classical arguments under a quantum predicate:
 * its all-zero-mask controlled clone (__cq_q_qfma_000_t_ctl in a library build). */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
double qfma(double, double, double);
static double qd(double x0) { double x = x0; cq_theta(&x, 0.0); return x; }

double e_fma(double a, double b, double c, double q) {
  double x = qd(q), r = 0.0;
  if (x > 0.0)
    r = qfma(a, b, c);
  return cq_measure(r);
}
