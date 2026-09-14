#include "CQ.h"
/* phi ROOT that NO region claimed -> rung 0 fails -> "branch phase on a bare i1
   condition", anchored by PhiAnchor == BI.  Line 9 is the `if (b1)`. */
int main(void) {
    int a = 5;
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (a >= 3) { b1 = b0; }
    if (b1) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1);
}
