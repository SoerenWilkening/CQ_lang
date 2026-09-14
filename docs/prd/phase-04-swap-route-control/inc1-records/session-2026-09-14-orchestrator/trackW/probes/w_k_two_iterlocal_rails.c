/* w_k — TWO independent ITERATION-LOCAL rails under one `_Bool`, each measured
   inside the body. The `staleRailRecordRead` grouping-key probe: two rails from
   two mints are two registers and must NOT interfere. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int r = cq_theta(7, 0.25);
        int t = cq_theta(3, 0.125);
        if (b) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(t);
    }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
