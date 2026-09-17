// E1 — the hoisted rail `p` is read INSIDE the loop AND AFTER it. tu9q P0+P3's
// (ii-d) narrowing keeps "every user of the rail must be inside L"; this probes
// whether the composition with zujr's carried handle reopens it.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a) + cq_measure(p & 8);
}
int main(void) { return slice(4); }
