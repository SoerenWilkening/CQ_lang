// G4 — (L3) trigger, fourth construction: a bank cell prepared by cq_theta and
// then MUTATED in place inside the same loop, so the store's VALUE operand is a
// template-op result rather than an alloc-minted rail.
#include "CQ.h"
int slice(int u) {
    int c[3];
    int q = cq_theta(u, 0.5);
    for (int i = 0; i < 3; i++) {
        c[i] = cq_theta(c[i], 0.5);
        c[i] = c[i] + 1;
        if (c[i] & 1) cq_phi(0.2);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(c[0]);
}
int main(void) { return slice(4); }
