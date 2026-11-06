/* tests/calls probe, cq-c7ej5 (rule 22): memset_pattern16 on the bus, measured; the C oracle does the writes. */
#include "CQ.h"
int mp2(int x, int n, double th) {
  int a[8];
  cq_theta(&x, th);
  for (int i = 0; i < 8; i++) a[i] = 0x01020304;
  __asm__ volatile("" : : "r"(a));
  return cq_measure(a[n & 7] + x);
}
