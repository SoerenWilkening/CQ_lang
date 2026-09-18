/* slice_4jok_bank_hoisted_carried.c — bd `test_C_libtooling-4jok`, the COMPOSED ACCEPT SURFACE.
 *
 * ALL THREE COMPOSITION AXES AT ONCE: bd `zujr`'s (L3) RAIL-BANK exemption
 * (`bool b0[3]`), bd `zujr`'s CARRIED HANDLE (`int a`), and bd `tu9q` (ii-d)'s
 * HOISTED TEMPLATE RAIL (`p = q*3`).  (L3) is the one widening in bd `zujr` that
 * is NOT gated on `loopCarriedHandlePhi`, so this is the only slice in the family
 * that exercises it beside the carried handle. *
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
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        b0[i] = cq_theta(b0[i], 0.5);
        if ((p >> i) & 1) cq_phi(0.2);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
