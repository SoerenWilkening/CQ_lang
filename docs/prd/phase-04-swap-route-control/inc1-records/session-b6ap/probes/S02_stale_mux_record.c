// S02 — M-D's CUSTOMER: an op that reads the PRE-rotation record of the peeled
// mux rail, scheduled AFTER a chained `cq_theta` on that same rail. Classical at
// `declineStaleRecordOps` (:337); quantum only after the peel.
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int r = cq_theta(m, 0.2);      // CHAINED once `m` is tainted — rotates the mux rail
  int s = m + 1;                 // reads the PRE-Ry record of that same rail
  printf("%d\n", cq_measure(a) + cq_measure(r) + cq_measure(s) + cq_measure(n));
  return 0;
}
