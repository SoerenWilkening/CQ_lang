/* tests/calls probe, cq-nupr1 (rules 20, 24): the same through a volatile local. */
#include "CQ.h"
int fe2(int x, double th) {
  cq_theta(&x, th);
  volatile int o = 1;
  return cq_measure(o) + (x & 0);
}
