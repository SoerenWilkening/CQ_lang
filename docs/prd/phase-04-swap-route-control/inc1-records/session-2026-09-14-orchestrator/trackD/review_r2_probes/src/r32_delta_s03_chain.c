#include <stdio.h>
#include "CQ.h"
/* DELTA-SCOPE on S03's own round-2 rail: the reader `cq_measure(r3)` has a
   ROUND-1-tainted record operand (r3), so it is never in the delta; its staler
   r2 is a direct reader of the round-2 rail m. Does SOMETHING decline? */
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int r1 = cq_theta(m, 0.2);
  int r3 = cq_theta(r1, 0.7);
  int r2 = cq_theta(m, 0.6);
  printf("%d\n", cq_measure(a) + cq_measure(r3) + cq_measure(r2) + cq_measure(n));
  return 0;
}
