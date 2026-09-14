/* A2 — the CONDITION rail is CHAINED and rotated INSIDE the body, per trip:
   `b = cq_theta(b, .1); if (b) r = cq_theta(r, .2);`. `b` is loop-CARRIED and
   the read point sees a DIFFERENT state each trip. Blocked by the carve-out. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(7, 0.25);
    for (int k = 0; k < CQ_K; ++k) {
        b = cq_theta(b, 0.1);
        if (b) r = cq_theta(r, 0.2);
    }
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
