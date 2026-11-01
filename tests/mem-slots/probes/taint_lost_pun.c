#include "CQ.h"
// cq-erjd/cq-n58p/cq-0y74/cq-kuuf (gate 2a taint-h1): the read through the pointer is quantum (taint is sound
// where provenance is lost); lowering it is not built yet: a loud stop, never a classical read.
int xg; long G;
__attribute__((noinline)) void put(void) { *(int **)&G = &xg; }
__attribute__((noinline)) int get(void) { int *p = (int *)G; return *p; }
int taint_lost_pun(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  xg = x;
  put();
  return cq_measure(get());
}
