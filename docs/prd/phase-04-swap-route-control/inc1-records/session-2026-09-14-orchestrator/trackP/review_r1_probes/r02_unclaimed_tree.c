#include "CQ.h"
/* phi at an INTERIOR tree position that no region claimed -> "control flow",
   anchored by declAnchor == the tree ROOT node. */
int main(void) {
    int a = 5;
    int q = cq_theta(0, 0.7);
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (a >= 3) { b1 = b0; }
    if (b1 && q > 3) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(q);
}
