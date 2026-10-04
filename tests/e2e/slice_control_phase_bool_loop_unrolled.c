/* slice_control_phase_bool_loop_unrolled.c — the hand-unrolled twin of
   slice_control_phase_bool_loop.c (K = 3). Its golden must be BYTE-IDENTICAL to
   the rolled one (`e2e-phase-bool-loop-twin-identical`). STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    int q = 0; cq_theta(&q, 0.3);
    if (b) cq_phi(0.7);
    cq_theta(&q, 0.2);
    if (b) cq_phi(0.7);
    cq_theta(&q, 0.2);
    if (b) cq_phi(0.7);
    cq_theta(&q, 0.2);
    return cq_measure(b) + cq_measure(q);
}
