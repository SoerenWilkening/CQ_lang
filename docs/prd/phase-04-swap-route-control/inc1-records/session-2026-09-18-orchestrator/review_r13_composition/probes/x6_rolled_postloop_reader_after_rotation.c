// COMPOSITION ATTACK 1(a)/(e), the ROLLED spelling. x4 was fully unrolled by
// -O1 so it never exercised P2. Here the post-loop consumer of the hoisted rail
// is an OUT-OF-PLACE op (`t * 3`) placed AFTER the trailing non-diagonal gate on
// the rail's parent. If `dagInsertPoint` takes the LATEST anchor in the exit
// block, the `and_i32_hl_unc(h_t, h_q, 1)` lands AFTER `cqrt_ry_i32(h_q, .9)`
// and recomputes from a rotated parent: the rail is not |0> at its `cqrt_free`.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  q = cq_theta(q, 0.9);        /* non-diagonal on the rail's PARENT */
  int u = t * 3;               /* out-of-place consumer of the rail, AFTER it */
  return cq_measure(q) + cq_measure(r) + cq_measure(u);
}
