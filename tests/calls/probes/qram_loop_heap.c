/* tests/calls probe (cq-dxii, review w2a-qram-h2/p10): a classical loop storing into a QRAM object is not walked inline as pure classical
 * (it recorded one store for every trip: the bus was dirty at qram_free); it reaches loops-classical.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec qram_loop_heap.c -o qram_loop_heap.O1.ll */
#include "CQ.h"
#include <stdlib.h>
int p10(unsigned x0, double t, int c) {
  unsigned x = x0; cq_theta(&x, t);
  int *a = malloc(8 * sizeof(int));
  for (int i = 0; i < 8; i++) a[i] = i;
  a[x & 7] = c;
  int r = a[(x >> 3) & 7];
  free(a);
  return cq_measure(r);
}
