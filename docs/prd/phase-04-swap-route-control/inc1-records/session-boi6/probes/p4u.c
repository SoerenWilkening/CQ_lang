/* p4u — the FLAT hand-unrolled twin of p4 (K=2), i.e. slice_control_phase_bool_grover.c verbatim. */
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
