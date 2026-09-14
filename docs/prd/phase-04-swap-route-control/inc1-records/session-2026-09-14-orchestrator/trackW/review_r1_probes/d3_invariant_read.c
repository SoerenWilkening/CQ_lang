/* D3 — D1 plus a NON-control read of the loop-invariant rail `b` in the body,
   which is what puts markIfRailLocal's "accumulating loop-invariant tainted
   input" clause in play. */
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
        if (b) r = cq_theta(r, 0.3);
        s += cq_measure(u + (int)b);
    }
    return s + cq_measure(r);
}
int main(void) { return slice(); }
