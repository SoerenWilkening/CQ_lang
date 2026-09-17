// ATTACK: the Q-R1-1 / bd s82e shape MEETS this widening. The condition's operand
// is a HOISTED loop-invariant TEMPLATE rail (`q & 1`), the compare is hoisted too
// (which is what this bead newly admits), and after the loop a NON-DIAGONAL gate
// runs on the register the template rail COPIES, which is then measured.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}
