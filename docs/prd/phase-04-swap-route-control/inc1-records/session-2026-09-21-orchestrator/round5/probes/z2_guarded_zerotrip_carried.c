// Z2 — Z1 with zujr's carried handle as well (all three widenings on one guarded loop).
#include "CQ.h"
int slice(int u, int n) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[8];
    for (int i = 0; i < n; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(4, argc - 1); }
