/* w_f — Track L's W2 shape: iteration-local state prep under a COMPARE condition. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    int q = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int r = 7;
        if (q == 5) r = cq_theta(7, 0.2);
        s += cq_measure(r);
    }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
