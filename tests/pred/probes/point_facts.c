#include "CQ.h"
// USERCHECK f
// cq-fbqi (cq-2p1p, rules 8, 9, 14): remquo's shape. A block reached from a classical test (c == 0) and
// from a mixed one (c > 50 || x == 7) minted under the other arm; below them a quantum-exit loop runs
// under a predicate that reads x == 7 negated. The output reaches the loop only through the arm that
// minted that test: the join above carries a don't-care on the classical edge.
__attribute__((noinline)) int h(int d) { __asm__ volatile("" ::: "memory"); return d; }
int f(int a, int b) {
  int x = a;
  cq_theta(&x, 0.3);
  int r = 0;
  if (h(b) == 0 || h(b) > 50 || x == 7) {
    r = x * b + 1;
  } else if ((x & 15) == 0) {
    unsigned u = (unsigned)x << 4;
    while ((int)u > 0) {
      u <<= 1;
      r--;
    }
  } else {
    r = x - 2;
  }
  return cq_measure(r) + cq_measure(x);
}
