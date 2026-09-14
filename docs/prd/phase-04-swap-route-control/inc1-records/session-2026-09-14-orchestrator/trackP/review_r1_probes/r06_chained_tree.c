#include "CQ.h"
/* the same wire decline with the phi at an INTERIOR tree position. */
int main(void) {
    int q = cq_theta(0, 0.7);
    bool b0 = cq_theta((bool)0, 0.5);
    bool r  = cq_theta((bool)0, 0.7);
    if (b0) { r = cq_theta(r, 0.3); }
    if (r && q > 3) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(r) + cq_measure(q);
}
