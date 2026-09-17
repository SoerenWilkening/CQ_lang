// COMPOSITION ATTACK 2. Does Group 1's g8 BACKSTOP fire on a body Track D newly
// ADMITS? The loop body is MULTI-BLOCK and its ARM mints an INTERIOR rail
// (`(d+7)&2`) — the exact g8 door — while the region's condition is a HOISTED
// loop-invariant compare, which the ORACLE refuses at P4 before any of this is
// reachable. Expected: ORACLE DECLINE `condition predates…`; COMBINED DECLINE
// `rolled body leaks a rail entangled with a rotated register` (the backstop).
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  int s = 0;
  for (int k = 1; k <= 4; ++k) {
    if (t == 1) r = cq_theta(r, 0.9);
    int d = (q >> k);
    s += cq_measure(d & 1);
    if (k < 3) { int e = d + 7; s += cq_measure(e & 2); }
  }
  q = cq_theta(q, 0.9);
  return s + cq_measure(q) + cq_measure(r);
}
