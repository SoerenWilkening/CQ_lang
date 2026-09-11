/* p4 — the one-qubit Grover loop (the ROLLED spelling of slice_control_phase_bool_grover.c). */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int k = 0; k < 2; k++) {
        if (b) cq_phi(3.14159);
        b = cq_theta(b, -0.5);
        if (!b) cq_phi(3.14159);
        b = cq_theta(b, 0.5);
    }
    return cq_measure(b);
}
