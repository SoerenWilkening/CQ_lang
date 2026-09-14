#include "CQ.h"
/* a phi leaf DEEP in the tree (depth 2) plus two compares -- the interior
   position bd 4aiu opened, exercised past depth 1. */
int main(void) {
    int q = cq_theta(0, 0.7);
    int r = cq_theta(0, 0.9);
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (q > 3 && (b1 && r > 5)) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(q) + cq_measure(r);
}
