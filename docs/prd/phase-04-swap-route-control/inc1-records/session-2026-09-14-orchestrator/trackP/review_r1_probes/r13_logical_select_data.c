#include "CQ.h"
/* BRIEF item 2: AllowRailPhi and AllowLogicalSelect must stay ORTHOGONAL.
   `(b1 && q > 3) ? A : B` from plain C must still decline on the LOGICAL-SELECT
   NODE at the 4.4 data select, not on the phi. */
int main(void) {
    int q = cq_theta(0, 0.7);
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    int a = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    a = (b1 && q > 3) ? 2 : 5;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a) + cq_measure(q);
}
