// E3 — THE THIRD COMPOSITION AXIS: zujr's (L3) RAIL-BANK exemption (the one
// widening in bd zujr that is NOT gated on loopCarriedHandlePhi) composed with
// tu9q (ii-d)'s hoisted template rail. `bool b0[3]` is the bank; `p = q*3` is
// the hoisted rail; `a` is the carried handle. All three at once.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        b0[i] = cq_theta(b0[i], 0.5);
        if ((p >> i) & 1) cq_phi(0.2);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
