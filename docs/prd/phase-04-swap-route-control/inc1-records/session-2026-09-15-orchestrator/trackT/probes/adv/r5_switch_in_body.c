/* R2-5 — a tainted-condition REGION inside the body (L2).  `railLocalQualifies`
   must refuse while a tainted branch is still standing at round 1. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) {
        int u = cq_theta(6, 0.4);
        if ((y >> k) & 1) cq_phi(0.3);
        s += cq_measure(u);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
