#include "CQ.h"
#include <stdlib.h>
// USERCHECK f
// USERCHECK g2
// cq-172vi: exit on a compare's false edge; a static callee that ends in abort there.
int g;
static __attribute__((noinline)) void thr(int v) {
  if (v & 1) abort();
  g += 1;
}
int f(int a) {
  cq_theta(&a, 1.0);
  if (a & 2) exit(3);
  return cq_measure(a);
}
int g2(int a) {
  cq_theta(&a, 1.0);
  thr(a);
  return g + cq_measure(a);
}
