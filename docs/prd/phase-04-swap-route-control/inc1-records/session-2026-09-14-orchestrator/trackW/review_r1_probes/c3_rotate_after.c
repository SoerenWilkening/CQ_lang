/* C3 — a NON-DIAGONAL gate on the condition's own wire, in the body AFTER the
   region: per activation it precedes trip 2's read of `b`. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(7, 0.25);
    for (int k = 0; k < CQ_K; ++k) { if (b) r = cq_theta(r, 0.2); b = cq_theta(b, 0.1); }
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
