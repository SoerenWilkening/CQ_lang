/* R2-H2 — an IN-LOOP PHASE region (8h7d.5, pre-existing, NO record) whose
   marking is refused by a loop-invariant tainted read, beside a per-trip derived
   chain.  The `d4` question for the phase path. */
#include "CQ.h"
int slice(void) {
    int  y = cq_theta(5, 0.5);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        if ((u >> 1) & 1) cq_phi(0.3);
        s += cq_measure((u >> 2) & 1) + cq_measure(y & 1);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
