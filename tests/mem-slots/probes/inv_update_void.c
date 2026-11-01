#include "CQ.h"
/* cq-xivx (CR §1.4 _inv<c>, rules 6, 18; probe p19 of review w2a-calls4-n1): as inv_update_result, a void
   callee. */
static __attribute__((noinline)) void dbl(int *p, int n) { p[0] = p[0] * 3 + n; }
int inv_update_void(int a0, double t, int n) {
  int a[1] = {a0};
  cq_theta(&a[0], t);
  dbl(a, n);
  return cq_measure(a[0]);
}
