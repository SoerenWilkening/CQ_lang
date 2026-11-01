/* tests/calls probe (cq-dxii, review w2a-qram-h2/p9): a classical loop storing into a QRAM object is not walked inline as pure classical
 * (it recorded one store for every trip: the bus was dirty at qram_free); it reaches loops-classical.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec qram_loop_stack8.c -o qram_loop_stack8.O1.ll */
#include "CQ.h"
int p9(unsigned x0, double t, int c) {
  unsigned x = x0; cq_theta(&x, t);
  int a[8];
  for (int i = 0; i < 8; i++) a[i] = i * c;
  a[x & 7] = c;
  return cq_measure(a[(x >> 3) & 7] + a[2] * 3);
}
