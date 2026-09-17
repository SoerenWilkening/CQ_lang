// F3 — an EARLY RETURN out of the loop body: a second exit block that is not the
// normal one. Same obligation as F2 for `loopExitDischargePoint`.
#include "CQ.h"
int slice(int u, int lim) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
        if (i == lim) return cq_measure(a);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(4, argc + 1); }
