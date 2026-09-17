// I2 — THE P1 SHAPE I AM HUNTING: the composed accept of d1/e3 PLUS a SECOND
// interior rail, minted in the body from `q` itself (so conjunct (3)'s
// `taintedAncestryReaches(&I, Rots)` is TRUE for it), whose discharge point the
// value arm's join may refuse. If the marking silences the dephasing fence and
// this rail is left undischarged across `cqrt_ry_i32(q,0.9)`, that is a Rule-8
// wrong unitary at opt exit 0.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= (q & 7);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
