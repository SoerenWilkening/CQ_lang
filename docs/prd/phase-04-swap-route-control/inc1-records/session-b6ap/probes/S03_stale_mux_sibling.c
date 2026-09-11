// S03 — the F-1b-1 SIBLING shape on the peeled mux rail: two chained thetas on
// one rail, the second read naming the stale first.
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int r1 = cq_theta(m, 0.2);
  int r2 = cq_theta(m, 0.6);
  printf("%d\n", cq_measure(a) + cq_measure(r1) + cq_measure(r2) + cq_measure(n));
  return 0;
}
