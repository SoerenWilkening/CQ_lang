// H1 — tu9q's own ht_rolled.c made MULTI-EXIT by a classical break, so
// `loopExitDischargePoint` returns nullptr. If (ii-d) still granted the marking,
// the hoisted rail `p` (a which-path copy of q) leaks across cqrt_ry_i32(q,0.9)
// with `declineDephasingUnmarkedLoopRails` conjunct (1) already silenced — the
// exact hazard `declineUndischargedExitObligations` exists to backstop.
#include "CQ.h"
int slice(int u, int lim) {
    int q = cq_theta(u, 0.5);
    int r = cq_theta(u, 0.3);
    int p = q * 3;
    for (int i = 0; i < 3; i++) {
        if (i >= lim) break;
        if ((p >> i) & 1) cq_phi(0.2);
        r = cq_theta(r, 0.1);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(4, argc + 1); }
