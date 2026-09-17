// D1u — the HAND-UNROLLED twin of d1_both_arms_post.c.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];

    if ((p >> 0) & 1) cq_phi(0.2);
    if (a >= 3) b0[0] = cq_theta(b0[0], 0.5);
    if (b0[0]) a -= 3;

    if ((p >> 1) & 1) cq_phi(0.2);
    if (a >= 3) b0[1] = cq_theta(b0[1], 0.5);
    if (b0[1]) a -= 3;

    if ((p >> 2) & 1) cq_phi(0.2);
    if (a >= 3) b0[2] = cq_theta(b0[2], 0.5);
    if (b0[2]) a -= 3;

    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
