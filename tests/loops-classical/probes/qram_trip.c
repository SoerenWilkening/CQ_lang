#include "CQ.h"
/* CR rules 14, 20, F1b (72, 188): QRAM stores in a classically bounded trip; the reverse loop pops them after the
   later accesses of the array. q_fill: a fill loop at classical offsets, then a quantum-index store; q_hist: a
   read-modify-write at a quantum bucket per trip. */
int q_fill(unsigned x0, double th, int c) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4];
  for (int i = 0; i < 4; i++) a[i] = x + i;
  a[x & 3] = c;
  return cq_measure(a[1] + a[2]);
}
int q_hist(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int h[4] = {0};
  for (int i = 0; i < 3; i++) h[(x >> 2 * i) & 3]++;
  return cq_measure(h[0] | h[1] << 4 | h[2] << 8 | h[3] << 12);
}
