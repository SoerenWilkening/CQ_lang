// U3 — the parent is relabelled ONCE, AFTER the loop but BEFORE nothing: the
// discharge point is the loop exit, and `q ^= 1` sits in the exit block.  Whether
// the adjoint lands before or after the relabelling is a PLACEMENT question tu9q P2
// newly owns.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int r = cq_theta(u, 0.3);
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        r = cq_theta(r, 0.1);
    }
    q = q ^ 1;
    return cq_measure(q) + cq_measure(r);
}
int main(void) { return slice(4); }
