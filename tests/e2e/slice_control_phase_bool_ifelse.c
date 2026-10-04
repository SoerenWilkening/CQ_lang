/* slice_control_phase_bool_ifelse.c — bd 3qlq.4 (PRD row P2 on a rail):
   `if (b) cq_phi(A); else cq_phi(B);` on a `_Bool`. clang -O1 folds the two arms
   into ONE `cq_phi` whose angle is `select i1 %b, double A, double B` — the
   Rz-stem ANGLE SELECT. On a register the kickback pair is `rz(h, -B)` (fires on
   b == 0, diagonal form) then `rz(h, A)`: two gates, no subtraction, no ancilla,
   no mint, no strip, no free. STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    if (b) cq_phi(0.9); else cq_phi(0.3);
    return cq_measure(b);
}
