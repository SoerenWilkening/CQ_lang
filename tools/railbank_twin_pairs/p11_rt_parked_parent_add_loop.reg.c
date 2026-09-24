/* the ARRAY-FREE twin of p11. */
#include "CQ.h"
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  for (int k = 0; k < n; ++k) q += k;
  s += cq_measure(q);
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }
