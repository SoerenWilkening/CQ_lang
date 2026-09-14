/* D2 — the CONTROL: D1 with the rail region removed (pre-existing capability). */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    int r = cq_theta(7, 0.25);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int u = cq_theta(5, 0.5);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2);
        s += cq_measure(u);
    }
    return s + cq_measure(r);
}
int main(void) { return slice(); }
