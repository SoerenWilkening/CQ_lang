#include "CQ.h"
// cq-erjd/cq-n58p/cq-0y74/cq-kuuf (gate 2a taint-h1): the read through the pointer is quantum (taint is sound
// where provenance is lost); lowering it is not built yet: a loud stop, never a classical read.
int xg; int *G; int *H;
__attribute__((noinline)) void cp(void) {
  unsigned char *d = (unsigned char *)&H, *s = (unsigned char *)&G;
  for (int i = 0; i < (int)sizeof(int*); i++) { ((volatile unsigned char*)d)[i] = s[i]; }
}
__attribute__((noinline)) int get(void) { return *H; }
int taint_lost_bytecp(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  xg = x; G = &xg;
  cp();
  return cq_measure(get());
}
