// G1 — zujr's (L3) RETIREMENT TRIGGER, re-measured on the COMPOSED binary.
// (L3)'s written ground is: "every rail a bank can hold today IS alloc-minted,
// so (I1) alone suffices"; its trigger is "the day a bank cell can hold a
// TEMPLATE-minted rail, (I1) stops covering it and only (I3) does. Re-derive
// this exemption then." The gap was MEASURED EMPTY on the zujr oracle and
// subject -- but NOT on a binary carrying tu9q P0+P3, which is precisely the
// increment that teaches the tree to treat template-minted rails as roots.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    bool b[3];
    for (int i = 0; i < 3; i++) {
        b[i] = (q >> i) & 1;      // a TEMPLATE-minted rail parked in a bank cell
    }
    int s = 0;
    for (int i = 0; i < 3; i++) {
        if (b[i]) cq_phi(0.2);
    }
    q = cq_theta(q, 0.9);
    return s + cq_measure(q);
}
int main(void) { return slice(4); }
