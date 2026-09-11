// R01 — r20 with the helper taking TWO tainted args (the mux AND the region's φ).
#include <stdio.h>
__attribute__((noinline)) static int helper(int x, int y) { return x + y; }
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3); a = cq_theta(a, 0.4);
  int m = 5;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; }
  int t = helper(m, a);
  printf("%d\n", cq_measure(t));
  return 0;
}
