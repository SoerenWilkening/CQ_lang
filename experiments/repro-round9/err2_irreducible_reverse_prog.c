#include "CQ.h"
int G[16];
__attribute__((noinline)) void e(int i) { G[i & 15] += 1; }
__attribute__((noinline)) int f(int q, int b, int n, double *p) {
  if (q) return 0;
  if (b && *p < 0) return 1;
  for (int i = 0;; i++) {
    e(i);
    if (i >= n) break;
    e(-i);
    if (i >= 7) break;
  }
  *p = 1.0;
  return 0;
}
int entry(int b, int n, double *p) {
  int q = cq_theta_si32(3, 1.0);
  return f(q, b, n, p);
}
