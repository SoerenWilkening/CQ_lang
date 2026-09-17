/* ATTACK B4 on the c2 conversion: THE HOISTED RAIL'S BORROWED PARENT (`y`) IS
   GATED INSIDE THE BODY.  The `y & 1` rail can no longer be loop-invariant:
   a rail minted on trip 1 stands at a non-diagonal gate fired on trip 2. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
        u = cq_theta(u, 0.9);
        y = cq_theta(y, 0.2);        /* <-- the delta */
        s += cq_measure(u);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
