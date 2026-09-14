#include "CQ.h"
/* the phi whose prep arm is on the FALSE edge (ClassArmFalse == InPlaceRotation):
   the `||` half of preppedRailPhiRegionIdx. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (!b0) { b1 = cq_theta(b1, 0.5); }
    if (b1) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1);
}
