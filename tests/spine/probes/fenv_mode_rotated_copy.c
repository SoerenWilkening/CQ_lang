/* tests/spine probe (CR rule 23 with rule 2's cq_theta; cq-181j): `int m = fegetround(); cq_theta(&m, t);` where the mode is a
 * rail: m is bound to the MODE rail, which eff-fenv also binds to a detached probe key. The Ry hits a copy of it; the
 * environment keeps its rail. It crashed in beginPreRotation (functionOf of the detached key).
 * Regenerate fenv_mode_rotated_copy.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h fenv_mode_rotated_copy.c */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
#pragma clang fp exceptions(ignore)
double p5(double x0, double th, double k, double a, double b, double th2) {
  double x = x0;
  cq_theta(&x, th);
  fesetround(x > k ? FE_UPWARD : FE_DOWNWARD);
  int m = fegetround();
  cq_theta(&m, th2);
  double s = a + b;
  fesetround(FE_TONEAREST);
  return cq_measure(s) + (double)cq_measure(m);
}
