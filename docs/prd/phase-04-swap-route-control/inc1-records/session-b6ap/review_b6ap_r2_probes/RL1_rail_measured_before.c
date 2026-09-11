// RL1 — the r9e5 rung-(ii) fence through the PEEL: the rail-root condition is
// MEASURED before the peeled selects' read point.
#include "CQ.h"
int main(void) {
  int a = 5, c = 11;
  bool b0 = 0;
  if (a >= 3) b0 = cq_theta(b0, 0.5);
  int m = cq_measure(b0);
  if (b0 == 1) { a -= 3; c -= 4; }
  return m + cq_measure(a) + cq_measure(c);
}
