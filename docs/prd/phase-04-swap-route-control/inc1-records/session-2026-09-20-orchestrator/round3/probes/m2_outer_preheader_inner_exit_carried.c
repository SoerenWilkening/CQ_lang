// M2 — M1 with zujr's CARRIED HANDLE in the inner body: the composed spelling of
// the same multiplicity question.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[4];
    for (int o = 0; o < 2; o++) {
        for (int i = 0; i < 2; i++) {
            if ((p >> i) & 1) cq_phi(0.2);
            b0[o * 2 + i] = cq_theta(b0[o * 2 + i], 0.5);
            if (b0[o * 2 + i]) a -= 3;
        }
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
