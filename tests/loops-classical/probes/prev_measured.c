/* tests/loops-classical probe (cq-jos4q, CR rules 2, 14, §1.3): the previous trip's value (a header phi) measured after
 * a classical loop whose other exit value is read in place (the reverse deferred after its readers). Its copy out is the
 * loop's output, kept by the measurement: the deferred reverse never un-copies nor frees it. Regenerate
 * prev_measured.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec prev_measured.c
 * -o prev_measured.O1.ll */
#include "CQ.h"
int pm_old(int x0, double t, int n) {
  int x = x0, old;
  cq_theta(&x, t);
  int i = 0;
  do { old = x; x = x * 3 + 1; } while (++i < n);
  return cq_measure(old) + x;
}
int pm_both(int x0, double t, int n) {
  int x = x0, old;
  cq_theta(&x, t);
  int i = 0;
  do { old = x; x = x * x + 1; } while (++i < n);
  return cq_measure(x) + cq_measure(old);
}
