// L01 — the peeled mux becomes a LOOP TRIP COUNT. `lowerLoops` (:365) ran before
// the peel and is NOT in adjudicateTaintDelta's four calls: Q1 ("loop under
// quantum control") was asked while `m` was still classical.
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 2;
  if (q == 5) { a = cq_theta(a, 0.9); m = 4; }
  for (int i = 0; i < m; i++) a = cq_theta(a, 0.1);
  printf("%d\n", cq_measure(a));
  return 0;
}
