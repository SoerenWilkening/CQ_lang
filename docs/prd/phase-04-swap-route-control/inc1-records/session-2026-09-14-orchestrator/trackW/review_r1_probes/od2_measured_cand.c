/* OD2 — clause (c) with NO loop-invariant tainted register (so markIfRailLocal
   is never called) and the body's ONLY template rail is MEASURED, i.e. nothing
   for the spine to discharge. bodyHasSpineDischargeCandidate counts it anyway. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        bool t = cq_theta((bool)0, 0.5);
        int r = cq_theta(7, 0.25);
        if (t) r = cq_theta(r, 0.2);
        s += cq_measure(r + 1) + cq_measure(t);
    }
    return s;
}
int main(void) { return slice(); }
