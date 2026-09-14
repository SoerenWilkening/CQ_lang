#include "CQ.h"
/* rung (ii) walks condProvenance(phi) = {phi, seed, theta}.  It does NOT reach
   the PREP'S CONDITION register b0.  Measure b0 before everything. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    int m = cq_measure(b0);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1) cq_phi(0.3);
    return m + cq_measure(b1);
}
