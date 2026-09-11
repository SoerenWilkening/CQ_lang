// A01 — item 8: a peeled ANGLE select handed to a Phase-6 candidate that the
// re-asked `detectSpecializations` can now see.
#include <stdio.h>
__attribute__((noinline)) static int helper(int x, double ang) { return x + (int)ang; }
int main(void) {
  int q = 0, b = 0;
  q = cq_theta(q, 0.3);
  double ang = 0.1; int n = 1;
  if (q == 5) { ang = 0.7; n = 2; }
  b = cq_theta(b, ang);
  int t = helper(b, ang);
  printf("%d %d\n", cq_measure(t), cq_measure(n));
  return 0;
}
