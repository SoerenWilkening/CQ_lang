// ⚠ DEGENERATE, and the header below overstates what it tests (corrected at the
// site, CLAUDE.md L7-with-a-twist). `-O1` FULLY UNROLLED this K=2 loop, so no
// `!llvm.loop` survives and Group 1's P2 loop-exit anchor is never exercised:
// D-alone and COMBINED emit md5-identical modules. The ROLLED spelling that does
// exercise P2 is x6_rolled_postloop_reader_after_rotation.c (verified rolled in
// the lowered IR). Read this pair as a -O1 unroll-heuristic artefact, not a
// measurement about the anchor.
// COMPOSITION ATTACK 1(a)+(e). P2 anchors the hoisted rail's discharge at the
// loop EXIT; `dagInsertPoint` then takes the LATEST anchor in that block. Give
// the rail a POST-LOOP consumer that sits AFTER the trailing non-diagonal gate
// on its parent, and the discharge is pushed past that gate: `and_i32_hl_unc`
// would then recompute `h_q & 1` from a ROTATED `h_q` — the adjoint stops
// inverting its forward, so the rail is not |0> and its `cqrt_free` is a hidden
// measurement (Rule 6), on top of the Rule-8 record.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  q = cq_theta(q, 0.9);        /* non-diagonal on the rail's PARENT */
  int u = t + 3;               /* post-loop consumer of the rail, AFTER it */
  return cq_measure(q) + cq_measure(r) + cq_measure(u);
}
