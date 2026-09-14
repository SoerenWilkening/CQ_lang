/* w_i — clause (c) with NO loop-invariant tainted register at all: the CONDITION
   is iteration-local too. `invariantRegisterRoots` then has no root to supply,
   so `markIfRailLocal` is never called and the body is never marked. */
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
        s += cq_measure(r) + cq_measure(t);
    }
    return s;
}
int main(void) { return slice(); }
