/* (g) bd 1yeu — TWO FUNCTIONS in one module. */
#include "CQ.h"
__attribute__((noinline)) static int k1(void){ int a = 5; bool b0[3];
  for (int i = 0; i < 3; ++i) { if (a >= 3) b0[i] = cq_theta(b0[i], 0.5); if (b0[i]) a -= 3; }
  return cq_measure(b0[0]) + cq_measure(a); }
__attribute__((noinline)) static int k2(void){ int c = 9; bool d0[3];
  for (int i = 0; i < 3; ++i) { if (c >= 4) d0[i] = cq_theta(d0[i], 0.25); if (d0[i]) c -= 4; }
  return cq_measure(d0[2]) + cq_measure(c); }
int main(void){ return k1() + k2(); }
