/* F-5 probe a: the canonical rail-bank accept COMPOSED with E2 clause (1a).
   The bank's three measures must still emit cqrt_measure_i1. */
#include "CQ.h"
int slice(void) {
    bool b0[3];
    int u;                      /* uninitialised -> undef at the measure */
    int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    s += cq_measure(u);         /* E2 clause (1a): accepts as zero, no trace line */
    return s;
}
int main(void) { (void) slice(); return 0; }
