// COMPOSITION ATTACK 6c. The observable is a DERIVED value of the rotated
// register, not the register itself — the blast scan keys on the register.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q * 5) + cq_measure(r);   /* observable is DERIVED */
}
