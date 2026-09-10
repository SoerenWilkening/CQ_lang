/* slice_control_phase_bool_grover.c — bd 3qlq.4: the one-qubit Grover-shaped
   program a `_Bool` user writes first — prepare, mark |1> (`if (b)`), un-prepare,
   reflect about |0> (`if (!b)`), re-prepare; two iterations WRITTEN OUT; measure.
   Every branch phase rides the register itself: `rz(h, π)` for the oracle,
   `rz(h, −π)` for the reflection (fires on b == 0: equal to X·P(π)·X up to the
   global phase e^{iπ}), interleaved with the user's Ry. Eleven lines, one rail,
   no ancilla, nothing minted, nothing freed.

   ⚠ WRITTEN FLAT ON PURPOSE. The `for (k < 2)` spelling makes `b` LOOP-CARRIED,
   so the header's condition is the rail PHI rather than a `cq_theta_i1` result,
   and that is this increment's documented residual (`branch phase on a bare i1
   condition`; fixture control_phase_kickback_reject_bare_i1_loop_phi.ll).
   A loop over an INVARIANT `_Bool` lowers rolled (slice_control_phase_bool_loop).
   STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    if (b) cq_phi(3.14159);
    b = cq_theta(b, -0.5);
    if (!b) cq_phi(3.14159);
    b = cq_theta(b, 0.5);
    if (b) cq_phi(3.14159);
    b = cq_theta(b, -0.5);
    if (!b) cq_phi(3.14159);
    b = cq_theta(b, 0.5);
    return cq_measure(b);
}
