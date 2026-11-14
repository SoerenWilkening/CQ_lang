/* tests/spine probe (CR rule 6 "A seed (rule 7) is freed directly instead"; cq-181j p6a, cq-4yzy collapse2): fetestexcept after
 * its flags' sources are measured is the host call, seeded where taint records the flags quantum; `+ a` reads the seed.
 * The seed is freed directly, never rule-6-cleaned by a copy (which left it in no known basis state: the verifier's
 * free-without-unc).
 * Regenerate seed_freed_directly.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h seed_freed_directly.c */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
int collapse_in_arm(int b, double x0, double c, double th) {
  double x = x0; cq_theta(&x, th);
  double y = 0.0;
  if (b) { y = x * c; (void)cq_measure(x); }
  return fetestexcept(FE_ALL_EXCEPT) + (int)cq_measure(y);
}
int p6d(double x0, double th, double k, int a) {
  double x = x0;
  cq_theta(&x, th);
  if (x > k)
    feraiseexcept(FE_OVERFLOW);
  double xm = cq_measure(x);
  (void)xm;
  return fetestexcept(FE_ALL_EXCEPT) + a;
}
