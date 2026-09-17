// K-independence control for the e3 composed accept: K = 3.
#include "CQ.h"
#define K 1000
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[K];
    for (int i = 0; i < K; i++) {
        b0[i] = cq_theta(b0[i], 0.5);
        if ((p >> i) & 1) cq_phi(0.2);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
