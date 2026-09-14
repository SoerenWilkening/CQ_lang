#include "CQ.h"
/* step 6 wire decline at a phi ROOT -> "condition predates a non-diagonal gate",
   PhiAnchor == BI.  The arm theta is CHAINED on the condition's own register. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool r  = cq_theta((bool)0, 0.7);
    if (b0) { r = cq_theta(r, 0.3); }
    if (r) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(r);
}
