// J3 — zujr's (Z8) GUARDED loop (a runtime trip bound, so the preheader alloc is
// bypassed on the zero-trip edge -- bd h1ip) composed with tu9q's hoisted rail.
// (Z8) is a DECLINE-direction conjunct; the question is whether tu9q's marking
// reaches the same loop by another route.
#include "CQ.h"
int slice(int u, int n) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[8];
    for (int i = 0; i < n; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(4, argc + 2); }
