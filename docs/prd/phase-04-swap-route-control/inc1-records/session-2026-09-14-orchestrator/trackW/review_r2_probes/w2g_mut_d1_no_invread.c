/* D1 — a RAIL region on a loop-CARRIED register (clause (b'): granted with NO
   record and NO round-2 re-ask) in a body that ALSO mints a per-trip derived
   chain the SPINE must discharge. Blocked by the retired carve-out. */
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
        s += cq_measure(u);
    }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
