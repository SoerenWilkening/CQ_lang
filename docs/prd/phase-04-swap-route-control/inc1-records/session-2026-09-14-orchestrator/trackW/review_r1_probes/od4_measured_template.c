/* OD4 — the candidate is a NON-in-place template rail (`r & 3`) whose only
   consumer is a measurement: a measured rail is never uncomputed and never
   freed, so again nothing for the spine to place in the body. */
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
        s += cq_measure(r & 3) + cq_measure(t);
    }
    return s;
}
int main(void) { return slice(); }
