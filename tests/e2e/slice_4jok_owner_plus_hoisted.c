/* slice_4jok_owner_plus_hoisted.c — bd `test_C_libtooling-4jok`, the COMPOSED ACCEPT SURFACE.
 *
 * ⚠ THIS IS THE OWNER'S OWN SHIPPED PROGRAM (`example/grover/
 * grover_oracle_uncompute.c`, the rolled cascade of `CLAUDE.md` §4e) WITH ONE
 * LINE ADDED: a LICM-hoisted `p = q*3` rail read by the body.  It is not an
 * exotic corner; it is the next line of the program this project ships. *
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
int main(void) {
    int q = 5; cq_theta(&q, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        if ((p >> i) & 1) cq_phi(0.2);
        if (a >= 3) {
            cq_theta(&b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a) + cq_measure(q);
}
