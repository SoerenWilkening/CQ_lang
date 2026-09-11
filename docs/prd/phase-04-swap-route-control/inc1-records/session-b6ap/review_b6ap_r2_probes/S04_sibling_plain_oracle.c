// S04 — bd `3d8q` WITHOUT ANY PEEL: two sibling chained thetas on one tainted
// rail, both measured. Reproduces on `main` — the control that says S03's stream
// is PRE-EXISTING and not the peel's.
#include <stdio.h>
int main(void) {
  int q = 0;
  q = cq_theta(q, 0.3);
  int m = q + 1;
  int r1 = cq_theta(m, 0.2);
  int r2 = cq_theta(m, 0.6);
  printf("%d\n", cq_measure(r1) + cq_measure(r2));
  return 0;
}
