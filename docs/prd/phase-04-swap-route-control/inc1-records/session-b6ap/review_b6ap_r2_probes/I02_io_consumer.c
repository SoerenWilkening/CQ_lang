// I02 — the peeled mux is the value of an UNCONDITIONAL 7.6 output sink
// (`lowerIOSinks`, :571, which runs AFTER the peel).
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  printf("%d\n", m);
  printf("%d %d\n", cq_measure(a), n);
  return 0;
}
