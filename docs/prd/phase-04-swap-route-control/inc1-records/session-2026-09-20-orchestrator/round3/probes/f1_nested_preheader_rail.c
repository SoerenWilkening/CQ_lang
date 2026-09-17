// F1 — THE MULTIPLICITY SHAPE. The template rail `t` is minted in the OUTER
// body, i.e. in the INNER loop's PREHEADER, so it runs K_outer times; the inner
// body is marked and runs K_outer*K_inner times. If the discharge is placed in
// the inner body we get K_inner adjoints against ONE forward gate per outer trip
// (Rule 8 double-uncompute / use-after-free). zujr's carried handle `a` crosses
// the INNER back edge.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int a = 5;
    bool b0[2];
    for (int o = 0; o < 2; o++) {
        int t = q * (o + 3);
        for (int i = 0; i < 2; i++) {
            if ((t >> i) & 1) cq_phi(0.2);
        }
        if (a >= 3) b0[o] = cq_theta(b0[o], 0.5);
        if (b0[o]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
