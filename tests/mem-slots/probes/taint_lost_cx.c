#include "CQ.h"
// cq-erjd/cq-n58p/cq-0y74/cq-kuuf (gate 2a taint-h1): the read through the pointer is quantum (taint is sound
// where provenance is lost); lowering it is not built yet: a loud stop, never a classical read.
int xg, yg; int *G = &yg;
__attribute__((noinline)) int *swap(void) {
  int *exp = &yg;
  __atomic_compare_exchange_n(&G, &exp, &xg, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
  return exp;
}
int taint_lost_cx(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  xg = x;
  swap();
  int *p = swap();
  return cq_measure(*p);
}
