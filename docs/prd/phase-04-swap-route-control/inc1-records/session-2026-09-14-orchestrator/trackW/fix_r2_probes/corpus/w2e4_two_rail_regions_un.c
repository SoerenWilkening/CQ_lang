/* hand-unrolled twin (K=2) of R2-E4 — TWO sequential rail regions in one loop body. */
#include "CQ.h"
int slice(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = cq_theta((bool)0, 0.6);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    {
        if (b0) r = cq_theta(r, 0.3);
        if (b1) r = cq_theta(r, 0.4);
        s += 1;
    }
    {
        if (b0) r = cq_theta(r, 0.3);
        if (b1) r = cq_theta(r, 0.4);
        s += 1;
    }
    return s + cq_measure(r) + cq_measure(b0) + cq_measure(b1);
}
int main(void) { return slice(); }
