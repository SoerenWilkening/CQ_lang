// COMPOSITION ATTACK 1/5, second spelling: a genuinely MULTI-EXIT loop. x1's
// `return 7` was merged by -O1 into ONE exit block with a phi (the 5th
// neutralised attempt in this family; group1 F-5 counted four). Here the two
// exits land in blocks with DIFFERENT content so SimplifyCFG has nothing to
// hoist. If `getUniqueExitBlock()` is null, P2's anchor returns nullptr, the
// component is abandoned, the hoisted rail LEAKS — and conjunct (3) never sees
// a PREHEADER-minted rail, so no obligation is recorded and the g8 backstop is
// blind to it.
#include <CQ.h>
volatile int sink;
int main(void) {
  volatile int lim_v = 2;
  int lim = lim_v;
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 4; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
    if (i == lim) goto early;
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
early:
  sink = 5;
  return cq_measure(r) + 1;
}
