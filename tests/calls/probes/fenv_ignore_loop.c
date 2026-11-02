/* tests/calls probe (cq-4e6m; CR rules 14, 23 ruling 2026-11-02): fpexcept.ignore constrained ops (-frounding-math,
 * musl's flags) inside rule-14 loops are plain templates, not a call class (musl __rem_pio2_large's constrained
 * fptosi in a classically bounded loop over a slot array). Regenerate: clang -O1 -frounding-math fenv_ignore_loop.c */
#include "CQ.h"
double il_loop(unsigned k0, double t, double x) {
  unsigned k = k0; cq_theta(&k, t);
  double s = x;
  for (unsigned i = 0; i < (k & 3); i++) s = s * 0.5 + (double)(int)(s * 3.0);
  return cq_measure(s);
}
double il_array(double a, double t) {
  double x = a; cq_theta(&x, t);
  int q[4];
  double z = x;
  for (int i = 0; i < 4; i++) { q[i] = (int)(z * 0.25); z = z * 2.0 - (double)q[i]; }
  return cq_measure(z + q[1] + q[3]);
}
