/* the ARRAY-FREE twin of p09: the parked name is `c`, read n times after the Ry. */
#include "CQ.h"
__attribute__((noinline)) int slice(int n, int seed) {
  if (n <= 1) return 0;
  int q = cq_theta(seed, 0.5);
  int c = q; int s = 0;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s + cq_measure(q);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }
