/* OD3 — clause (c), no invariant root, and the body's candidate is an IN-PLACE
   op (`r ^= 3`), which mints no rail for the spine to reverse. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        bool t = cq_theta((bool)0, 0.5);
        int r = cq_theta(7, 0.25);
        if (t) r = cq_theta(r, 0.2);
        r = r ^ 3;
        s += cq_measure(r) + cq_measure(t);
    }
    return s;
}
int main(void) { return slice(); }
