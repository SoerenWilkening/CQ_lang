/* hand-unrolled twin (K=2) of R2-E8 — the rail region beside a strictly-deeper CLASSICAL loop. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    {
        if (b) r = cq_theta(r, 0.3);
        for (int j = 0; j < 3; ++j) s += j;
    }
    {
        if (b) r = cq_theta(r, 0.3);
        for (int j = 0; j < 3; ++j) s += j;
    }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
