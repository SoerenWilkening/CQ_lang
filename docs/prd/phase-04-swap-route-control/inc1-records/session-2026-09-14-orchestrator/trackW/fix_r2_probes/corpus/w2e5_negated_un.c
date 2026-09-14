/* hand-unrolled twin (K=2) of R2-E5 — the NEGATED bare-`_Bool` arm in a loop (Ry additivity). */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    {
        if (!b) r = cq_theta(r, 0.3);
        s += 1;
    }
    {
        if (!b) r = cq_theta(r, 0.3);
        s += 1;
    }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
