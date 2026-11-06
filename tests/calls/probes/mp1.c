/* tests/calls probe, cq-c7ej5 (rule 22): LoopIdiom makes the store loop memset_pattern16 over a QUANTUM cell. */
#include "CQ.h"
/* loop idiom memset_pattern16 over a cell holding a quantum value */
int mp1(int x, int n, double th) {
  int a[8];
  cq_theta(&x, th);
  n &= 7;
  a[n] = x;
  __asm__ volatile("" : : "r"(a));
  int s = a[n];
  for (int i = 0; i < 8; i++) a[i] = 0x01020304;
  __asm__ volatile("" : : "r"(a));
  return cq_measure(a[n] + s);
}
