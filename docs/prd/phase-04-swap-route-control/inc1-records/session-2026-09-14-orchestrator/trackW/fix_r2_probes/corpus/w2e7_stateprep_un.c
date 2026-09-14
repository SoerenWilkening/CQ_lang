/* hand-unrolled twin (K=2) of R2-E7 — in-loop controlled STATE PREP under a bare `_Bool` (clause (c) with
   `MintSeed = T`). */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  s = 0;
    {
        int r = 4;
        if (b) r = cq_theta(4, 0.3);
        s += cq_measure(r);
    }
    {
        int r = 4;
        if (b) r = cq_theta(4, 0.3);
        s += cq_measure(r);
    }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
