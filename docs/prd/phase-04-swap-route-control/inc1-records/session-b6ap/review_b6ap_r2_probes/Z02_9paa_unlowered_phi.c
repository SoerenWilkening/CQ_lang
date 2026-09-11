// Z02 — Z01 with a THIRD register as R2's condition, so gate 2c is clean: the
// peel's delta contains R2's own merge phi, which is NOT yet lowered when
// `detectSpecializations` runs at its third program point (fix OQ3 / bd 9paa).
#include <stdio.h>
__attribute__((noinline)) static int helper(int x) { return x + 1; }
int main(void) {
  int q = 0, a = 0, c = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  c = cq_theta(c, 0.6);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int z = 0;
  if (c > 3) z = m;                      // R2's own merge phi over the peeled mux
  int t = helper(z);
  printf("%d %d %d\n", cq_measure(a), cq_measure(t), cq_measure(n));
  return 0;
}
