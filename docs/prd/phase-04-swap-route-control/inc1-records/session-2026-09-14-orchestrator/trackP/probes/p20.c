#include "CQ.h"
/* TWO prep phis in ONE condition tree at the PHASE consumer (bd 4aiu:
   PrepRegionIdxs is a list because a tree may carry several phi leaves). */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    bool b2 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b0) { b2 = cq_theta(b2, 0.9); }
    if (b1 && b2) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2);
}
