// X3 -- 6n1s ledger: ACCEPTOR first, the g8 arm-minted-rail OFFENDER second.
#include "CQ.h"
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
__attribute__((noinline)) int OFFENDER(int lim) {
    int y = cq_theta(5, 0.5);
    int a = 5;
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);
        if (k < lim) { int e = d + 7; s += cq_measure(e & 2); }
        if (a >= 3) a -= 3;
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y) + cq_measure(a);
}
int main(int argc, char **argv){ (void)argv; return ACCEPTOR(4) + OFFENDER(argc+1); }
