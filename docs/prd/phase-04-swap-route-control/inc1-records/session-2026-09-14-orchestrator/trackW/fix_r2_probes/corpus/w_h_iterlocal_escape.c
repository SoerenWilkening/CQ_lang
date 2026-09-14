/* w_h — the ITERATION-LOCAL rotated register ESCAPES `L` (measured after the
   loop), which is what makes `markIfRailLocal` refuse the body marking. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    int q = cq_theta(5, 0.5);
    int r = 0;
    for (int k = 0; k < CQ_K; ++k) {
        r = cq_theta(7, 0.25);
        if (q == 5) r = cq_theta(r, 0.2);
    }
    return cq_measure(r) + cq_measure(q);
}
int main(void) { return slice(); }
