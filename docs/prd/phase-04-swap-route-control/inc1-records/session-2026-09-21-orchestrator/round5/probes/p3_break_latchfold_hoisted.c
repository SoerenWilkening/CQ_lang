// P3 — a LATCH-FOLDED `break` (the anchor's comment: `-O1` if-converts a break into
// one extra latch disjunct, so the loop stays SINGLE-exit and IS reached by the P2
// anchor walk) combined with the composition's enabling ingredients (a rail bank and
// a carried handle), so that the earlier walls round 3's e5/h1/h2 died at are gone.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
        if (a < 0) break;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
