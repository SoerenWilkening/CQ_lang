/* slice_loop_pairing_rootmint_unrolled.c — the HAND-UNROLLED twin (K=2) of
   `slice_loop_pairing_rootmint.c`. Its golden is compared byte-for-byte with the
   rolled one by `e2e-loop-pairing-rootmint-twin-identical`; that comparison is the
   ONLY instrument in the tree that can see the bd `tu9q` class, because STRICT
   stage 2b counts `cqrt_alloc` SITES and the leaked rail is TEMPLATE-minted (it
   reported `0 violation(s), 0 unproven` on the leaking form too).

   ⚠ Byte identity cannot prove the PAIR correct — if both halves were wrong the
   same way the witness is blind (`CLAUDE.md` L10's `m_none_pbitd_none_premark_
   rypost` cell). What it proves is that rolling the loop changed nothing, and the
   FLAT stream is the one this compiler has emitted since Phase 5. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    s += cq_measure((y >> 1) & 1);
    s += cq_measure((y >> 2) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
