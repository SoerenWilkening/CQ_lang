/* w_c — the COMPARE spelling of w_a: loop-INVARIANT compare condition.
   CLAUDE.md row W says -O1 LICM-hoists it and P4 refuses the cross-block gap. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    int x = cq_theta(0, 0.5);
    int r = cq_theta(7, 0.25);
    for (int k = 0; k < CQ_K; ++k) { if (x == 3) r = cq_theta(r, 0.2); }
    return cq_measure(r) + cq_measure(x);
}
int main(void) { return slice(); }
