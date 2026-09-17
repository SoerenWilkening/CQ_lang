// COMPOSITION ATTACK 1/5. `dD1` with ONE extra line: a SECOND EXIT from the loop.
// Track D admits the hoisted compare (P4 -> crossBlockCompareMintable); Group 1's
// P2 anchor is what DISCHARGES the hoisted template rail at the loop exit, and
// `loopExitDischargePoint` returns nullptr for a MULTI-EXIT loop, so the anchor
// walk abandons the component and the rail LEAKS.
// The fence behind it does NOT cover this rail: `declineDephasingUnmarkedLoopRails`
// conjunct (3) enumerates `L->blocks()` only, and `t = q & 1` is minted in the
// PREHEADER — so nothing records an obligation and the g8 BACKSTOP never sees it.
// Expected if that reading is right: ORACLE/G1 DECLINE (P4), COMBINED ACCEPT with
// a dirty template rail across `cqrt_ry_i32(h0,0.9)` and `h0` measured (Rule 8).
#include <CQ.h>
int main(void) {
  volatile int lim_v = 2;
  int lim = lim_v;
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 4; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
    if (i == lim) return 7;          /* SECOND EXIT BLOCK */
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}
