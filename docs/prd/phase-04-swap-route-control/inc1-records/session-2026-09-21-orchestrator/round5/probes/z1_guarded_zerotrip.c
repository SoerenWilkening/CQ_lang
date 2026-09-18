// Z1 — THE ZERO-TRIP PATH OF A GUARDED LOOP.  tu9q P2 anchors the hoisted rail's
// discharge at `loopExitDischargePoint(L)` = the loop's UNIQUE EXIT BLOCK.  The
// forward gate `p = q*3` is minted BEFORE the loop, i.e. before `-O1`'s zero-trip
// GUARD.  If `-O1` gives the loop a DEDICATED exit block (LCSSA), the guard's
// false edge BYPASSES it -- so on the n<=0 path the forward gate RAN and the
// adjoint+free did NOT, leaving a live record of `q` across the trailing
// `cq_theta(q, 0.9)`: a Rule-8 wrong unitary ON ONE PATH ONLY, which no golden
// (one trip count per run) and no K-independence check can see.
#include "CQ.h"
int slice(int u, int n) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    bool b0[8];
    for (int i = 0; i < n; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(b0[0]);
}
int main(int argc, char **argv) { (void)argv; return slice(4, argc - 1); }
