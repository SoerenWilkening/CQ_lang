/* bd xdu2.1 (Track B): runtime bank; a runtime-trip `q += k` loop on the
   parked parent, q measured, then the cells. */
#include "CQ.h"
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = seed; cq_theta(&q, 0.5);
  int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;
  for (int k = 0; k < n; ++k) q += k;
  s += cq_measure(q);
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }
