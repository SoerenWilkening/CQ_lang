// E2 — TWO loops share ONE hoisted rail `p`, each with its own carried handle.
// The (ii-d) grant is per-loop; the discharge anchor is a loop EXIT. Two loops
// reading one preheader-minted rail is the shape where "one forward gate, K
// adjoints" would show up as TWO `_unc` against ONE mint.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    int c = 7;
    bool b0[3];
    bool b1[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    for (int j = 0; j < 3; j++) {
        if ((p >> j) & 2) cq_phi(0.3);
        if (c >= 4) b1[j] = cq_theta(b1[j], 0.4);
        if (b1[j]) c -= 2;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a) + cq_measure(c);
}
int main(void) { return slice(4); }
