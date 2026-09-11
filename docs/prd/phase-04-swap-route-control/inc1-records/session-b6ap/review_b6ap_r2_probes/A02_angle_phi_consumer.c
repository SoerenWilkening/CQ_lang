// A02 — a peeled ANGLE select consumed by `cq_phi` (the register-free branch
// phase) BESIDE a data mux, with the escape net now in front of it.
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  double ang = 0.1; int n = 1;
  if (q == 5) { ang = 0.7; n = 2; }
  cq_phi(ang);
  printf("%d %d\n", cq_measure(a), cq_measure(n));
  return 0;
}
