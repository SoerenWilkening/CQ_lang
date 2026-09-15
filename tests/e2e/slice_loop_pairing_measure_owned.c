/* slice_loop_pairing_measure_owned.c — bd `test_C_libtooling-tu9q` clause (ii-c),
   the MEASURE-OWNED loop-invariant rail, at the only layer that LINKS.

   `-O1` LICM hoists the loop-invariant `y & 1` into the preheader, so the body
   reads a hoisted TEMPLATE rail rather than the register — the `z_preheader_rail8`
   case `invariantRegisterRootsImpl`'s header records as refused, and refusing it
   took the discharge of the body's genuinely iteration-local `(u >> 1) & 1` chain
   down with it (rolled 16 trace lines against the twin's 20 on the ORACLE).

   Clause (ii-c) admits that ONE rail because EVERY user of it is a `cq_measure`,
   which makes it MEASURE-OWNED: `ChainWalk::isInteriorTerminalHandle` clause (I3)
   refuses it and `FreePoint::computeFreePoint` returns `FreePointKind::Measured`
   for it, so NEITHER partition can place an `At` for it and the "K adjoints
   against ONE forward gate" multiplicity hazard is unbuildable with this spelling.
   It is therefore STILL LEFT ALLOCATED, in both spellings — what changed is only
   that the loop is now marked.

   ⚠ NO `*-twin-identical` GATE FOR THIS PAIR, and the reason is a STAGE-1 fact
   rather than a lowering one: `-O1` HOISTS `y & 1` in the rolled spelling and CSEs
   the two copies into a mid-function one in the unrolled spelling, so the forward
   mint sits at a different point in the two streams BEFORE the pass runs. The gate
   SYMBOL MULTISET is identical (measured) and the two orderings are the same
   unitary — `cq_template_and_i32_hl(h0,1)` writes a fresh rail and the per-trip
   chain touches only its own, so they act on disjoint rails and commute. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
