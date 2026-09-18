// U2 — U1 with `q += 1` instead of `q ^= 1` (the other M-C in-place opcode).
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int r = cq_theta(u, 0.3);
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        r = cq_theta(r, 0.1);
        q = q + 1;
    }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { return slice(4); }
