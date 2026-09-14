#include "CQ.h"
/* rung (ii) at an INTERIOR phi leaf -> same string, declAnchor == tree root. */
int main(void) {
    int q = cq_theta(0, 0.7);
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    int m = cq_measure(b1);
    if (b1 && q > 3) cq_phi(0.3);
    return m + cq_measure(b0) + cq_measure(q);
}
