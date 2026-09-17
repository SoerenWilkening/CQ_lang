// M3 — M1 with NO loop-carried value at all: the only body content is the
// iteration-local chain reading the once-minted, doubly-invariant rail `p`.
// The (ii-d) conjuncts hold for the INNER loop; its exit block is inside the
// OUTER loop.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    for (int o = 0; o < 3; o++) {
        for (int i = 0; i < 3; i++) {
            if ((p >> i) & 1) cq_phi(0.2);
        }
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q);
}
int main(void) { return slice(4); }
