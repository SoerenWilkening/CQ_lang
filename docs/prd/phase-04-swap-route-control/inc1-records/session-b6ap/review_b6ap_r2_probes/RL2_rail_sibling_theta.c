// RL2 — the F-1b-1 SIBLING fence through the PEEL: a second `cq_theta` on the
// rail between its def and the peeled selects.
#include "CQ.h"
int main(void) {
  int a = 5, c = 11;
  bool b0 = 0, b1 = 0;
  if (a >= 3) b0 = cq_theta(b0, 0.5);
  b1 = cq_theta(b0, 0.9);
  if (b0 == 1) { a -= 3; c -= 4; }
  return cq_measure(b1) + cq_measure(a) + cq_measure(c);
}
