#include "CQ.h"
/* Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec partial_measure.c -o partial_measure.O1.ll */
/* CR rule 2 (cq-29ej): a rail measured on some classical paths only is lowered as unmeasured. */
int pm_ret(int a, int c) {          /* measured on an early return only */
  int x = a; cq_theta(&x, 1.0);
  int y = 3 * x + 1;
  if (c) return cq_measure(y);
  int z = y ^ 5;
  return cq_measure(x) + cq_measure(z & 1);
}
int pm_join(int a, int c) {         /* measured under a classical branch, read again after the join */
  int x = a; cq_theta(&x, 1.0);
  int y = x + 7, r = 0;
  if (c) r = cq_measure(y);
  return r + cq_measure(y * 3);
}
int pm_loop(int a, int n) {         /* measured on some trips of a classical loop */
  int x = a; cq_theta(&x, 1.0);
  int r = 0;
  for (int i = 0; i < n; i++) {
    int y = x + i;
    if (i & 1) r += cq_measure(y);
    r += cq_measure(y & 3);
  }
  return r;
}
