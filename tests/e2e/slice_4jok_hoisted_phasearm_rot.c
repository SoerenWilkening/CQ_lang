/* slice_4jok_hoisted_phasearm_rot.c — bd `test_C_libtooling-4jok`, the COMPOSED ACCEPT SURFACE.
 *
 * THE MINIMAL COMPOSITION: a LICM-hoisted `p = q*3` template rail read by the
 * body's phase-arm condition, a `bool b0[3]` RAIL BANK, and a trailing
 * NON-DIAGONAL gate on `q`.  Read the golden for the per-trip discharge
 * (`and -> icmp -> x -> rz_i1 -> x -> icmp_unc -> and_unc -> free -> free`) and
 * for the ONE `cq_template_mul_i32_hl_unc` + `cqrt_free` at the LOOP EXIT,
 * BEFORE the `cqrt_ry_i32(h0, 0.9)`.  That ordering is the whole Rule-8 claim.
 *
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
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
