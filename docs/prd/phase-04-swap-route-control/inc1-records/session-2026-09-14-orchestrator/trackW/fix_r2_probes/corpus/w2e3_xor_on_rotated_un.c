/* hand-unrolled twin (K=2) of R2-E3 — the rotated register is ALSO read out-of-place by a body op. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    {
        if (b) r = cq_theta(r, 0.3);
        s += cq_measure(r ^ 5);
    }
    {
        if (b) r = cq_theta(r, 0.3);
        s += cq_measure(r ^ 5);
    }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
