// R03 — r20 with an INLINABLE helper (no `noinline`): -O1 inlines it, so no
// Phase-6 candidate exists at all.
#include <stdio.h>
static int helper(int x) { return x + 1; }
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3); a = cq_theta(a, 0.4);
  int m = 5;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; }
  int t = helper(m);
  printf("%d %d\n", cq_measure(a), cq_measure(t));
  return 0;
}
