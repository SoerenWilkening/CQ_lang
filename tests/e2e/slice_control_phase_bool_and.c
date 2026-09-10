/* slice_control_phase_bool_and.c — bd 3qlq.4 (PRD row P3 with a rail leaf):
   `if (b && q == 5) cq_phi(θ)` — a condition TREE whose left leaf is the `_Bool`
   register itself (clang -O1: `select i1 %b, i1 %cmp, i1 false`). The compare
   leaf mints its flag as before; the rail leaf mints nothing and is a Toffoli
   CONTROL into the node ancilla; the phase rides the ancilla; the LIFO strip
   frees the ancilla and the compare flag only — the register gets no gate.
   STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int q = cq_theta(0, 0.3);
    if (b && q == 5) cq_phi(0.9);
    return cq_measure(b) + cq_measure(q);
}
