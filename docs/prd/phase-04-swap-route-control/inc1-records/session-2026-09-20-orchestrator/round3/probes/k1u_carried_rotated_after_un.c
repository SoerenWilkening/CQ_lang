// K1u — the HAND-UNROLLED twin of k1_carried_rotated_after.c.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];

    if ((p >> 0) & 1) cq_phi(0.2);
    b0[0] = cq_theta(b0[0], 0.5);
    if (b0[0]) a -= 3;

    if ((p >> 1) & 1) cq_phi(0.2);
    b0[1] = cq_theta(b0[1], 0.5);
    if (b0[1]) a -= 3;

    if ((p >> 2) & 1) cq_phi(0.2);
    b0[2] = cq_theta(b0[2], 0.5);
    if (b0[2]) a -= 3;

    a = cq_theta(a, 0.7);
    return cq_measure(a) + cq_measure(q);
}
int main(void) { return slice(4); }
