/* tests/calls probe. */
#include "CQ.h"
/* cq-nupr1's other side: reached through a pointer the same body is its table clone, its object bus-resident, the load a rail */
__attribute__((noinline)) int pk(int k) {
  int a[2] = {k, k + 1};
  return cq_measure(a[k & 1]);
}
int fe6(int x, int k, double th) {
  int (*volatile fp)(int) = pk;
  cq_theta(&x, th);
  int d = pk(k);
  int c = fp(x);
  return cq_measure(x + c + d);
}
