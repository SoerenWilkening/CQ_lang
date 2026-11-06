/* tests/calls probe. */
#include "CQ.h"
/* rule 22, a rail length: the store loop's bound is quantum, K2 trips, p_j per byte. 4 and 8 byte patterns */
long g[8];
int mp5(int x, int n, double th) {
  cq_theta(&x, th);
  unsigned m = x & 7;
  for (unsigned i = 0; i < m; i++) g[i] = 0x0102030405060708L;
  __asm__ volatile("" : : "r"(g));
  return cq_measure((int)g[n & 7] + (int)g[0]);
}
