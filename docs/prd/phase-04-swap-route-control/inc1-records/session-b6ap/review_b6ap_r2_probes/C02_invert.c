// C02 — the peeled mux's derived chain inside a `cq_invert_begin/_end` bracket
// (the Phase-8 manual inversion region).
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  cq_invert_begin();
  int w = m * 3;
  cq_invert_end();
  printf("%d %d %d\n", cq_measure(a), cq_measure(n), cq_measure(w));
  return 0;
}
