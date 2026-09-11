/* slice_control_phase_bool_loop_iterlocal.c — Track A.1, Rule-13 round-1
   finding F-A1-2: the e2e witness for the increment's TWO ACCEPT-direction
   movers. The condition register is ITERATION-LOCAL — minted fresh inside the
   body — and it is MEASURED in the body, after the control read.

   `main` 0c7380c DECLINES this program `condition measured before the control
   route`; it lowers here. The accept is right, and the TRACE is what says so:
   three DISTINCT handles, h0/h1/h2, one alloc+ry+rz+measure group per trip. Each
   measurement collapses the register ITS OWN trip minted, never the one the next
   trip's kickback controls on. `isPotentiallyReachable(M, ReadPoint)` alone is
   TRUE around any back edge and cannot see that; the per-activation barrier
   (`railMeasuredBeforeReadPoint`, the wire ORIGIN when it is a SOURCE theta) is
   what asks "on the SAME register?".

   Twin witness: slice_control_phase_bool_loop_iterlocal_unrolled.c, gated
   byte-identical (`e2e-phase-bool-loop-iterlocal-twin-identical`). The select
   spelling of the same shape is the lit fixture
   control_swap_select_rail_inloop_iterlocal_measure_after.ll. STRICT stage 2b —
   nothing is freed, and nothing should be: a measured rail is left allocated
   (Rule 6's safe direction). Source: review_a1_r1_probes/b1.c, with the external
   `ext(i)` replaced by `i` so the slice is self-contained. */
#include "CQ.h"

int slice(void) {
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) cq_phi(0.3);
        acc += cq_measure(b) + i;
    }
    return acc;
}

int main(void) {
    (void) slice();
    return 0;
}
