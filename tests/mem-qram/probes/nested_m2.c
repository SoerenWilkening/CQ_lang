#include "CQ.h"
/* M2 through a call (CR rules 18, 21): a clone hands its QRAM triple formal on to a clone that stores through it. */
__attribute__((noinline)) static void put(int *p, int v) { p[1] = v; }
__attribute__((noinline)) static int outer(int *p, int v) {
  put(p, v + 1);
  return p[1] + p[0];        /* reads the callee's store (forwarded) and a cell it did not write */
}
int nested_m2(unsigned x0, double th, int k) {
  unsigned x = x0;
  cq_theta(&x, th);
  int a[4] = {k, k + 1, k + 2, k + 3};
  a[x & 3] = 7;              /* a quantum-index store: a is a QRAM */
  int r = outer(a, (int)(x & 15));
  return cq_measure(r) * 100 + cq_measure(a[(x >> 1) & 3]);
}
