/* e03 — the CONTROL for e01: the same sibling shape with `x` TAINTED AT ROUND 1
   (derived from q directly). The Inc-1b F-1b-1 widening must DECLINE it. */
#include "CQ.h"
int main(void) {
  int q = 0; q = cq_theta(q, 0.2);
  bool x = (bool)(q & 1);
  bool b  = cq_theta(x, 0.5);
  bool b3 = cq_theta(x, 0.9);
  int a = b ? 2 : 5;
  return cq_measure(a) + cq_measure(b3) + cq_measure(q);
}
