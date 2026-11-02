#include "CQ.h"
// USERCHECK g
// cq-fbqi (rules 8, 13, 16): atan2l's shape. Under a classical test, a quantum branch whose arms are
// quantum switches with an unreachable default: the branch has no post-dominator in LLVM's tree, its
// region ends at the join of the live arms, where the merge still reads the branch's flag.
__attribute__((noinline)) int h(int d) { __asm__ volatile("" ::: "memory"); return d; }
int g(int a, int b) {
  int x = a;
  cq_theta(&x, 0.3);
  int r;
  if (h(b) > 2) {
    if (x == 5) {
      switch (x & 3) {
      case 0: r = h(b) * 3; break;
      case 1: r = h(b) + 11; break;
      case 2: r = h(b) - 4; break;
      case 3: r = h(b) ^ 6; break;
      default: __builtin_unreachable();
      }
    } else {
      switch ((x >> 2) & 3) {
      case 0: r = h(b) * 5; break;
      case 1: r = h(b) + 13; break;
      case 2: r = h(b) - 8; break;
      case 3: r = h(b) ^ 9; break;
      default: __builtin_unreachable();
      }
    }
  } else {
    r = x + 1;
  }
  return cq_measure(r) + cq_measure(x);
}
