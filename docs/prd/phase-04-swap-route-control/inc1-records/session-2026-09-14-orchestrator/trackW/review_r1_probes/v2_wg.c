/* w_g — a DERIVED condition ((q>>k)&1) over a loop-INVARIANT register, with an
   ITERATION-LOCAL rotated base. The C-1 leak family's shape. */
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
        s += cq_measure(r);
    }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
