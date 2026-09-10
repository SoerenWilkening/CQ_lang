/* slice_control_phase_bool_nest.c — bd 3qlq.4 (PRD row P4 with a rail root):
   the depth-2 nest `if (b) { cq_phi(.2); if (q == 5) cq_phi(.9); }` whose outer
   condition is the `_Bool` register. The outer arm's phase rides the register
   (`rz(h_b, .2)`, no mint); the conjunction `g = b ∧ (q==5)` is one Toffoli with
   the register as a control; the inner phase rides g. STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int q = cq_theta(0, 0.3);
    if (b) {
        cq_phi(0.2);
        if (q == 5) cq_phi(0.9);
    }
    return cq_measure(b) + cq_measure(q);
}
