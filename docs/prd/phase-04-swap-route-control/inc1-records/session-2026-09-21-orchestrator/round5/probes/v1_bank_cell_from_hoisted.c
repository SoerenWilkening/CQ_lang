// V1 — (L3)'s WRITTEN RETIREMENT TRIGGER: "the day a bank cell can hold a
// TEMPLATE-minted rail, (I1) stops covering it and only (I3) does."  Round 3
// measured that gap EMPTY with five constructions, but all five wrote the cell from
// `q` DIRECTLY.  (ii-d)'s whole subject is a HOISTED TEMPLATE RAIL, so this writes
// the cell from `p = q*3` instead -- the value the composition newly admits as a Root.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        b0[i] = (p >> i) & 1;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
