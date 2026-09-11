// K11 — a CHAINED `cq_theta` on the mux out-rail (arg-0).
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int r = cq_theta(m, 0.2);
  printf("%d\n", cq_measure(a) + cq_measure(r) + cq_measure(n));
  return 0;
}
