/* slice_4jok_twofn_hoisted_carried.c — bd `test_C_libtooling-4jok`, the COMPOSED ACCEPT SURFACE.
 *
 * TWO QUANTUM FUNCTIONS IN ONE MODULE, because bd `1yeu` records that every
 * corpus and gate in this tree is effectively ONE FUNCTION PER MODULE, so a
 * cross-function defect is invisible to all of them.  BOTH postconditions here
 * (`declineUndischargedMarkedBodyRails`, `declineUndischargedExitObligations`)
 * are MODULE-SCOPED ledgers that CLEAR THEMSELVES — this is the shape where
 * "cleared at both ends" could read an emptied ledger.  Each function carries
 * its own obligation and each discharges before its own trailing rotation. *
 * ⚠ THIS PROGRAM DECLINES ON THE PRE-LANDING COMPILER (`cq-opt` 8280ea8d…) and
 * compiles only with bd `zujr` AND bd `tu9q` P0+P3 BOTH present.  Neither
 * increment alone accepts it: they retire DIFFERENT clauses of
 * `railLocalQualifies` and neither retires the other's.  It is therefore a
 * COMPOSITION fixture — the class `CLAUDE.md` records five consecutive sessions
 * filing as *"a composition is not cleared by clearing its parts"*, and the
 * first one to be pinned by a test rather than asserted.
 *
 * ⚠ THE INSTRUMENTS IN THIS TREE REPORT ZERO ON THIS FAMILY and their silence
 * is not evidence: the 2109-fixture corpus A/B finds 0 composition-only movers,
 * the 382-cell twin matrix verdict tables are byte-identical, and all e2e
 * slices agree.  The surface is reachable only from C sources nobody committed
 * — which is why these slices exist.
 */
#include "CQ.h"
__attribute__((noinline)) int fa(int u) {
    int q = u; cq_theta(&q, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        cq_theta(&b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    cq_theta(&q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
__attribute__((noinline)) int fb(int u) {
    int q = u; cq_theta(&q, 0.3);
    int p = q * 5;
    int a = 7;
    bool b1[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 2) cq_phi(0.4);
        cq_theta(&b1[i], 0.6);
        if (b1[i]) a -= 2;
    }
    cq_theta(&q, 0.8);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return fa(4) + fb(6); }
