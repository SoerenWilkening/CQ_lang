/* D4 — D3 with the RAIL REGION REMOVED: `b` is still a loop-invariant tainted
   input read in the body, but there is no bare-_Bool control region at all.
   This is a PRE-EXISTING shape: it must be asked of the ORACLE. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(7, 0.25);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int u = cq_theta(5, 0.5);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2);
        s += cq_measure(u + (int)b);
    }
    return s + cq_measure(r);
}
int main(void) { return slice(); }
