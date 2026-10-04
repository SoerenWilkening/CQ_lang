/* slice_control_phase_bool_loop.c — bd 3qlq.4 (PRD row P6 with a rail):
   a bare-`_Bool` kickback ROLLED inside a classically-bounded loop, the
   condition register LOOP-INVARIANT and a second register rotated per trip.
   A compare on an invariant register is the documented `hoisted compare`
   over-decline; a rail has no compare to hoist, so this lowers rolled with one
   `rz` per activation and NOTHING minted per trip. Twin witness:
   slice_control_phase_bool_loop_unrolled.c, gated byte-identical
   (`e2e-phase-bool-loop-twin-identical`). STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    int q = 0; cq_theta(&q, 0.3);
    for (int i = 0; i < 3; ++i) {
        if (b) cq_phi(0.7);
        cq_theta(&q, 0.2);
    }
    return cq_measure(b) + cq_measure(q);
}
