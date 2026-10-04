/* bd xdu2.1 (Track B, 2026-09-24): p01 on the xdu2.4 RUNTIME-SIZED bank
   (`alloca i32, i64 %n`). Must DECLINE with the bd 3d8q string. */
#include "CQ.h"
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = seed; cq_theta(&q, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  cq_theta(&q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }
