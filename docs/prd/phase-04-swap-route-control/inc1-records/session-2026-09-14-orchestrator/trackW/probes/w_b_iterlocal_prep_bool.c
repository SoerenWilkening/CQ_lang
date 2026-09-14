/* w_b — the ITERATION-LOCAL in-loop STATE PREP under a bare-_Bool condition. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int r = 7;
        if (b) r = cq_theta(7, 0.2);
        s += cq_measure(r);
    }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
