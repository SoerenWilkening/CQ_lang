// K08 — the mux is a TERMINAL 7.6 output-tape value (`lowerIOSinks`, :571).
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  printf("%d\n", m);
  printf("%d\n", cq_measure(a) + cq_measure(n));
  return 0;
}
