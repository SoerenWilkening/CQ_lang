#include "CQ.h"
/* ONE prep phi conjoined with ONE plain RAIL leaf at the PHASE consumer — both
   leaves live in the kickback's own Pred, so the bd 4aiu interior-leaf accept
   covers a mixed phi+rail tree too. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b2 = cq_theta((bool)0, 0.9);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1 && b2) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2);
}
