/* tests/calls probe, cq-qmqch: hc1 with one call and no merge. */
#include "CQ.h"
/* control: hc1 without the merge, one call */
__attribute__((noinline)) static int cal(int v, int k) {
  int a[4] = {1, 2, 3, 4};
  a[k & 3] += 5;
  int t = v * a[(k + 1) & 3];
  return (t + a[k & 3]) >> 1;
}
int hc3(int x, int k, double th) {
  cq_theta(&x, th);
  return cq_measure(cal(x, k) + 1);
}
