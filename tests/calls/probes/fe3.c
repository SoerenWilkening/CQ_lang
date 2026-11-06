/* tests/calls probe, cq-nupr1 (rule 20): a measurement of a host-resident load is a classical read in the entry. */
#include "CQ.h"
int fe3(int x, int k, double th) {
  int a[2] = {k, k + 1};
  cq_theta(&x, th);
  int c = cq_measure(a[k & 1]);
  return cq_measure(x + c);
}
