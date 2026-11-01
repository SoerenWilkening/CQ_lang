#include "CQ.h"
// cq-erjd/cq-n58p/cq-0y74/cq-kuuf (gate 2a taint-h1): the read through the pointer is quantum (taint is sound
// where provenance is lost); lowering it is not built yet: a loud stop, never a classical read.
int xg; int yg = 7; int *G = &yg;
__attribute__((noinline)) int f(void) { int r = *G; G = &xg; return r; }
int taint_lost_reent(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  xg = x;
  f();
  return cq_measure(f());
}
