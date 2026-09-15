/* ADV-X1 — TRACK S′'s HAZARD, probed directly (orchestrator message, 2026-09-15).
   bd `2g52`'s shape (`for (k<3) z ^= v;` with `v` volatile — a dtzb IN-PLACE
   relabel that lowers to `cqrt_xorc_i32` and MINTS NOTHING) placed in a loop that
   ALSO has the measure-owned loop-invariant read clause (ii-c) admits.  If the
   pairing ever emitted an `_unc` + `cqrt_free` for the in-place op's rail it would
   be freeing a rail that was never allocated — a Rule-6 violation by
   construction. */
#include "CQ.h"
int slice(void) {
    volatile int v = 3;
    int y = cq_theta(5, 0.5);
    int z = cq_theta(7, 0.3);
    int s = 0;
    for (int k = 0; k < 3; ++k) {
        z ^= v;
        s += cq_measure(y & 1);
    }
    return s + cq_measure(y) + cq_measure(z);
}
int main(void) { return slice(); }
