// K06 — DELTA COMPLETENESS: the mux reaches an i32 `ret` (an ALLOWED escape).
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  printf("%d %d\n", cq_measure(a), n);
  return m;
}
