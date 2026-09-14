/* C1 — a clause-(c) loop with TWO tainted regions in the body (sequential,
   hcrg-ordered). Both mint per-trip template chains the spine must discharge. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    int q = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int r = cq_theta(7, 0.25);
        if ((q >> k) & 1) r = cq_theta(r, 0.2);
        if ((q >> k) & 2) r = cq_theta(r, 0.3);
        s += cq_measure(r);
    }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
