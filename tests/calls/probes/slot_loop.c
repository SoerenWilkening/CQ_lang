/* tests/calls probe (cq-dxii): a classical loop storing seeds into a slot object goes to loops-classical (rule 14) instead
 * of the inline pure-classical walk; §6 against the C program.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec slot_loop.c -o slot_loop.O1.ll */
#include "CQ.h"
int s1(int x0, double t, int n) {
  int x = x0; cq_theta(&x, t);
  int a[8];
  for (int j = 0; j < 8; j++) a[j] = j * n;
  a[n & 7] = x;
  return cq_measure(a[(n + 1) & 7] + a[n & 7]);
}
