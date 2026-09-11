// K04 — DELTA COMPLETENESS: the Phase-6 candidate reads the mux TWO HOPS away.
#include <stdio.h>
__attribute__((noinline)) static int helper(int x) { return x * 3; }
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int t = helper((m + 4) ^ 2);
  printf("%d %d %d\n", cq_measure(a), cq_measure(t), n);
  return 0;
}
