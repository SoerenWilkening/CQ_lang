/* w_e — the COMPARE twin of w_d: iteration-local rotated base, compare condition
   on a loop-INVARIANT register. (= control_inplace_ry_reject_inloop_iterlocal_base.ll) */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    int q = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int r = cq_theta(7, 0.25);
        if (q == 5) r = cq_theta(r, 0.2);
        s += cq_measure(r);
    }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
