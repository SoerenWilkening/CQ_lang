// L04 — a REAL rolled loop (an opaque cq_theta in the body stops -O1 closing the
// form): the in-place `a ^= m` immediate is the peeled mux. `lowerLoops` (:365)
// marked the op with `m` CLASSICAL; the peel makes it quantum afterwards.
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 3; }
  for (int i = 0; i < 4; i++) { a = cq_theta(a, 0.1); a = a ^ m; }
  printf("%d\n", cq_measure(a));
  return 0;
}
