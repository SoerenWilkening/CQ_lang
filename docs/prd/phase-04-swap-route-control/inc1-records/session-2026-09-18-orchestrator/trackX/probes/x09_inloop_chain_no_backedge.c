/* x09_inloop_chain_no_backedge.c — Track X (bd x5fp), session 2026-09-18.
   THE ISOLATING CONTROL for x08: identical, minus the back edge (`a` is a
   loop-invariant 0, the measure result accumulates into a separate variable).
   If x09 ACCEPTS and x08 declines §3c, then S-1 is the ONLY wall for x08 and
   the per-activation narrowing has a real accept witness. If x09 declines,
   the wall it names is BEHIND S-1 and x08 cannot accept either. */
#include "CQ.h"
int main(void) {
    int a = 0;
    int t = 0;
    for (int i = 0; i < 3; ++i) {
        int q = cq_theta(9, 0.3);
        int r = cq_theta(7, 0.2);
        if (q >= a) { r = r + 3; r = r * 2; r = r ^ 5; r = r + 7; }
        t += cq_measure(r);
    }
    return t;
}
