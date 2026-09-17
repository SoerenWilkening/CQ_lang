// ⚠ DEGENERATE for the same reason as x4 (see that file's corrected header):
// `-O1` fully unrolled it, so P2's loop-exit anchor is not exercised. The rolled
// control is x7_rolled_postloop_reader_before_rotation.c.
// ISOLATING CONTROL for x4: the SAME post-loop consumer of the hoisted rail,
// moved BEFORE the trailing rotation. The discharge point then precedes the
// non-diagonal gate and the adjoint inverts its forward.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  int u = t + 3;               /* post-loop consumer BEFORE the rotation */
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r) + cq_measure(u);
}
