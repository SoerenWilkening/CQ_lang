// Z01 — the fix's OQ3 (9paa) shape: the peel's delta contains a MERGE PHI of a
// region that is NOT YET LOWERED, and `detectSpecializations` at its THIRD
// program point enters the call reading it into `Pending`.
#include <stdio.h>
__attribute__((noinline)) static int helper(int x) { return x + 1; }
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int z = 0;
  if (a > 3) z = m;                      // R2's own merge phi over the peeled mux
  int t = helper(z);
  printf("%d %d\n", cq_measure(t), cq_measure(n));
  return 0;
}
