/* slice_4jok_nested_outer_carried.c — bd `test_C_libtooling-4jok`, the COMPOSED ACCEPT SURFACE.
 *
 * THE MULTIPLICITY SHAPE, and the reason this family needed adjudicating at all.
 * `railLocalQualifies`' final clause carries a written trigger: *"a recovered
 * gate in the PREHEADER (does not repeat) with `At` in a body marked here
 * (repeats K times) would emit K adjoints against ONE forward gate … no shipped
 * test would go red.  Re-derive the multiplicity there first."*  Here the
 * hoisted rail is outside BOTH loops and read by the INNER one, with the OUTER
 * running K times.  MEASURED: `cq_template_mul_i32_hl` is minted ONCE and
 * `_unc`'d ONCE — `anchorForConsumer` walks to the OUTERMOST exit. *
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
    for (int o = 0; o < 3; o++) {
        for (int i = 0; i < 3; i++) {
            if ((p >> i) & 1) cq_phi(0.2);
        }
        b0[o] = cq_theta(b0[o], 0.5);
        if (b0[o]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
