// X2 -- X1 with the ORDER REVERSED: the OFFENDER first, the ACCEPTOR second.
#include "CQ.h"
__attribute__((noinline)) int OFFENDER(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        if (q >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
__attribute__((noinline)) int ACCEPTOR(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    bool bz[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        bz[i] = cq_theta(bz[i], 0.5);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(bz[0]);
}
int main(int argc, char **argv){ (void)argv; return ACCEPTOR(4) + OFFENDER(argc+1); }
