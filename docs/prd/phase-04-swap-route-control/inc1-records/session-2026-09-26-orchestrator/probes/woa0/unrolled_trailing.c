/* G-13 standing probe, HAND-UNROLLED twin of rolled_trailing.c. */
#include "CQ.h"
int main(void) {
    int Z = 5; int P = 0;
    bool b0[3];
    if (Z >= 1) b0[0] = cq_theta(b0[0], 0.5);
    if (b0[0]) { Z -= 1; P += 3; }
    if (Z >= 2) b0[1] = cq_theta(b0[1], 0.5);
    if (b0[1]) { Z -= 2; P += 2; }
    if (Z >= 3) b0[2] = cq_theta(b0[2], 0.5);
    if (b0[2]) { Z -= 3; P += 1; }
    Z     = cq_theta(Z, 0.3);
    b0[0] = cq_theta(b0[0], 0.7);
    int x[3];
    x[0] = cq_measure(b0[0]); x[1] = cq_measure(b0[1]); x[2] = cq_measure(b0[2]);
    return cq_measure(Z) + cq_measure(P);
}
