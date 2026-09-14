#include "CQ.h"
/* A-8: the prep phi's ONLY user is the kickback's `br` — nothing measures b1.
   After the kickback's flatten the phi is USE-EMPTY, and what stops
   `flattenRegion` erasing it out from under the prep's later M-beta RAUW is the
   `isCondRailPhiShape` conjunct Track M added as defence in depth. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1) cq_phi(0.3);
    return cq_measure(b0);
}
