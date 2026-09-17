// G2 — (L3) trigger, int-cell spelling: an `int` bank whose cells hold
// template-minted rails, with a carried handle and a trailing rotation.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int c[3];
    int a = 5;
    for (int i = 0; i < 3; i++) {
        c[i] = q * (i + 2);
    }
    for (int i = 0; i < 3; i++) {
        if (c[i] & 1) cq_phi(0.2);
        if (a >= 3) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
