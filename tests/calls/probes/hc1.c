/* tests/calls probe, cq-qmqch (rules 5, 18): a plain store to a host-resident object writes memory, so the callee has no twin and its results are KEPT. */
#include "CQ.h"
/* host local in a callee, twin replay */
__attribute__((noinline)) static int cal(int v, int k) {
  int a[4] = {1, 2, 3, 4};
  a[k & 3] += 5;
  int t = v * a[(k + 1) & 3];
  return (t + a[k & 3]) >> 1;
}
int hc1(int x, int k, double th) {
  cq_theta(&x, th);
  int r;
  if (x & 1) r = cal(x, k); else r = cal(x + 1, k + 1);
  return cq_measure(r);
}
