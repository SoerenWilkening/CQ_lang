// E5 — a `break` (7.4) beside the carried handle and the hoisted rail. The
// (ii-d) discharge anchor is `loopExitDischargePoint`, which is `nullptr` for a
// MULTI-EXIT loop by construction; a break makes the loop multi-exit.
#include "CQ.h"
int slice(int u, int lim) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if (i >= lim) break;
        if ((p >> i) & 1) cq_phi(0.2);
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(4, argc + 1); }
