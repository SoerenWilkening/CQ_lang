#include "CQ.h"
/* rung (ii) at a phi ROOT: cq_measure(b1) BEFORE the branch ->
   "condition measured before the control route", PhiAnchor == BI. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    int m = cq_measure(b1);
    if (b1) cq_phi(0.3);
    return m + cq_measure(b0);
}
