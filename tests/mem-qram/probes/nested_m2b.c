#include "CQ.h"
/* M2 through a call (CR rules 18, 21): the clone's own store before the call, a store at an offset from a quantum
   idx, a callee under a quantum predicate (its stores flagged), and a later load of a cell both wrote. */
__attribute__((noinline)) static void put(int *p, int v) { p[0] = v; }
__attribute__((noinline)) static int outer(int *p, int v) {
  p[1] = v ^ 3;                 /* the clone's own deferred store */
  if (v & 1)
    put(p + 1, v + 5);          /* the callee's store, under a quantum predicate, at the same cell */
  return p[1] * 2 + p[2];       /* reads the last store to p[1] */
}
int nested_m2b(unsigned x0, double th, int k) {
  unsigned x = x0;
  cq_theta(&x, th);
  int a[8] = {k, k + 1, k + 2, k + 3, k + 4, k + 5, k + 6, k + 7};
  a[x & 7] = 9;                 /* a quantum-index store: a is a QRAM */
  int r = outer(a + (x & 3), (int)(x & 15));   /* the triple's idx is quantum */
  return cq_measure(r) * 100 + cq_measure(a[(x >> 2) & 7]);
}
