/* slice_control_phase_bool_loop_iterlocal_unrolled.c — the hand-unrolled twin of
   slice_control_phase_bool_loop_iterlocal.c (K = 3). Its golden must be
   BYTE-IDENTICAL to the rolled one (`e2e-phase-bool-loop-iterlocal-twin-identical`):
   three registers written out is exactly what three trips of one
   iteration-local register ARE, which is the whole ground of the F-A1-2 accept.
   STRICT stage 2b. */
#include "CQ.h"

int slice(void) {
    int acc = 0;
    bool b0 = (bool)0; cq_theta(&b0, 0.5);
    if (b0) cq_phi(0.3);
    acc += cq_measure(b0) + 0;
    bool b1 = (bool)0; cq_theta(&b1, 0.5);
    if (b1) cq_phi(0.3);
    acc += cq_measure(b1) + 1;
    bool b2 = (bool)0; cq_theta(&b2, 0.5);
    if (b2) cq_phi(0.3);
    acc += cq_measure(b2) + 2;
    return acc;
}

int main(void) {
    (void) slice();
    return 0;
}
