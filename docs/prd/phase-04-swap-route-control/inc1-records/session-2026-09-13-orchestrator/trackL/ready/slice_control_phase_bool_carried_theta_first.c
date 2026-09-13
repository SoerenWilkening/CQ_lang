/* slice_control_phase_bool_carried_theta_first.c — bd boi6 H-10: the SHIPPED
   in-loop accept that no fixture and no slice pinned before this file.

   A LOOP-CARRIED `_Bool` whose region condition is the IN-BODY chained theta.
   `b`'s identity crosses the back edge as a header phi, but the value the `if`
   reads is the body's own `cq_theta_i1` CALL, so Inc-1b's rail ladder admits it
   and `collapseFlattenedLoopRails` RAUWs the phi to the root mint: ONE
   `cqrt_alloc_i1` in the preheader, then per activation ONE `cqrt_ry_i1` and ONE
   `cqrt_rz_i1` on the register itself. Nothing minted, nothing stripped, nothing
   freed, no `cqrt_x` on a user register (Rule 7). The rail is LEFT ALLOCATED and
   measured — `Ry(θ)|0> != |0>`, so Rule 6 forbids freeing it.

   ROLLED: the lowered IR is independent of the trip count — MEASURED 50 lines at
   K=3 and 50 at K=1000 (`wc -l` of stage 2 on the K=1000 twin). The witness is
   byte identity with slice_control_phase_bool_carried_theta_first_unrolled.c
   (ctest e2e-phase-bool-carried-theta-first-twin-identical), 9 = 9 lines.

   ⚠ WHY IT MATTERS BEYOND ITSELF: it is the DISCRIMINATOR for bd boi6.a (admit
   the header PHI as a rail leaf, i.e. the theta AFTER the region — today
   `branch phase on a bare i1 condition`). This stream must be byte-unchanged
   across that widening. RETIREMENT TRIGGER: if boi6.a moves this golden, the
   widening is not stream-preserving and its clearance argument is void.
   STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; i++) {
        b = cq_theta(b, 0.2);
        if (b) cq_phi(0.7);
    }
    return cq_measure(b);
}
