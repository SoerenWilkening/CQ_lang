/* A1 — ITERATION-LOCAL CONDITION rail `b` (minted per trip, inside L) beside a
   loop-CARRIED rotated register `r`. Clause (b') grants Rollable, so clause (c)
   and its round-2 re-ask are NEVER asked. Blocked by the retired carve-out. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    int r = cq_theta(7, 0.25);
    for (int k = 0; k < CQ_K; ++k) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) r = cq_theta(r, 0.2);
    }
    return cq_measure(r);
}
int main(void) { return slice(); }
