// P1 — OUTER loop MULTI-EXIT (an early `return` inside it), INNER loop single-exit,
// the hoisted rail `p` minted OUTSIDE THE WHOLE NEST and read by the INNER body.
// (ii-d) is asked with L = the INNER loop, whose `loopExitDischargePoint` is
// NON-NULL, so the grant is made; `Uncomputation::anchorForConsumer` then computes
// LOut = the OUTERMOST loop not containing the mint = the OUTER loop, whose
// `loopExitDischargePoint` is NULL.  The clause checks one loop's exit and the
// placement uses another's.  Does the (ii-d) POSTCONDITION catch the leak?
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    bool b0[3];
    for (int o = 0; o < 3; o++) {
        if (o == 2 && u > 9) return cq_measure(q);   // second EXIT of the outer loop
        for (int i = 0; i < 3; i++) {
            if ((p >> i) & 1) cq_phi(0.2);
        }
        b0[o] = cq_theta(b0[o], 0.5);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
