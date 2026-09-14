/* C2 — the rail CONDITION is MEASURED in the body AFTER the region. Positionally
   the measure follows the read point; PER ACTIVATION it precedes trip 2's read. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(7, 0.25);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) { if (b) r = cq_theta(r, 0.2); s += cq_measure(b); }
    return s + cq_measure(r);
}
int main(void) { return slice(); }
