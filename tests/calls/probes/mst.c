/* tests/calls probe, cq-c7ej5 (rule 22): memset_pattern16 under a quantum predicate is controlled bus stores. */
#include "CQ.h"
/* -O1 turns a store loop under a quantum predicate into memset_pattern16 */
int mst(int x, int n, double th) {
  int a[8] = {0};
  cq_theta(&x, th);
  if (x & 1) { for (int i = 0; i < 8; i++) a[i] = 0x01020304; __asm__ volatile("" : : "r"(a)); }
  return cq_measure(a[n & 7]);
}
