/* QFT^-1 on four scalar qubits (no swaps), H = Ry(pi/2) Z, CPhase as `if (a && b) cq_phi(t)`. At -O1 the
 * short-circuit conditions are De-Morgan'd: negations hoisted as values, later conditions rewritten as or-selects. */
#include <math.h>
int qft4_demorgan(double th) {
    bool c0 = 0, c1 = 0, c2 = 0, c3 = 0;
    cq_theta(&c0, th); cq_theta(&c1, th); cq_theta(&c2, th); cq_theta(&c3, th);
    if (c3) cq_phi(M_PI); cq_theta(&c3, M_PI / 2);
    if (c3 && c2) cq_phi(-M_PI / 2);
    if (c2) cq_phi(M_PI); cq_theta(&c2, M_PI / 2);
    if (c3 && c1) cq_phi(-M_PI / 4);
    if (c2 && c1) cq_phi(-M_PI / 2);
    if (c1) cq_phi(M_PI); cq_theta(&c1, M_PI / 2);
    if (c3 && c0) cq_phi(-M_PI / 8);
    if (c2 && c0) cq_phi(-M_PI / 4);
    if (c1 && c0) cq_phi(-M_PI / 2);
    if (c0) cq_phi(M_PI); cq_theta(&c0, M_PI / 2);
    return cq_measure(c0) | cq_measure(c1) << 1 | cq_measure(c2) << 2 | cq_measure(c3) << 3;
}
