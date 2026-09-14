/* OD1 — iteration-local rotated register (reassigned unconditionally each trip,
   so the header phi is dead) with a BARE _Bool condition, read AFTER the loop.
   (c3) refuses. The body has NO spine-discharge candidate at all. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = 0;
    for (int k = 0; k < CQ_K; ++k) { r = cq_theta(7, 0.25); if (b) r = cq_theta(r, 0.2); }
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
