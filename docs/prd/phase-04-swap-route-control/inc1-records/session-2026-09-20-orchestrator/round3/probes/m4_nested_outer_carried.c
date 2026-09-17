// M4 — M3 with zujr's CARRIED HANDLE on the OUTER loop (so the inner loop stays
// free of a carried value and the (ii-d) conjuncts still hold for it).
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int o = 0; o < 3; o++) {
        for (int i = 0; i < 3; i++) {
            if ((p >> i) & 1) cq_phi(0.2);
        }
        b0[o] = cq_theta(b0[o], 0.5);
        if (b0[o]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
