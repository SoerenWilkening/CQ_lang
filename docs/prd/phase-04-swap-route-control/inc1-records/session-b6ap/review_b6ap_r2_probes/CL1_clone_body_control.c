// CL1 — the peel makes a call a Phase-6 candidate whose BODY contains control:
// `classifyCandidate`'s mask-independent `scanBody` must still decline LOUDLY at
// the third program point.
#include <stdio.h>
__attribute__((noinline)) static int helper(int x) { if (x > 6) return x + 1; return x - 1; }
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int t = helper(m);
  printf("%d %d %d\n", cq_measure(a), cq_measure(t), cq_measure(n));
  return 0;
}
