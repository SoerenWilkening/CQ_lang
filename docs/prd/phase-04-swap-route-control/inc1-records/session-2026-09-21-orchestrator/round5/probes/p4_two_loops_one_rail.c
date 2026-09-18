// P4 — ONE hoisted rail read by TWO sibling loops.  `allUsersInside(V, L)` is asked
// per loop; the second loop's readers are OUTSIDE the first loop, so the conjunct
// should refuse both.  If it grants for either, the rail is discharged at ONE loop's
// exit while the OTHER loop still reads it -> use-after-free of a rail, or a leak.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3], b1[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    for (int j = 0; j < 3; j++) {
        if ((p >> j) & 2) cq_phi(0.3);
        b1[j] = cq_theta(b1[j], 0.5);
        if (b1[j]) a -= 1;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
