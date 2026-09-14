#include "CQ.h"
/* IMPL §9.1's named over-decline (p20 sibling), re-measured independently:
   two SEPARATE prep diamonds conjoined -> the second phi is not in Pred. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    bool b2 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b0) { b2 = cq_theta(b2, 0.9); }
    if (b1 && b2) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2);
}
