/* R2-C DATING CONTROL — the SAME in-place body with NO control region at all,
   so both binaries accept both forms and the in-place-vs-out-of-place twin
   divergence can be dated independently of this increment. */
#include "CQ.h"
int slice(void) {
    int q = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) { q = q + 3; s += cq_measure(q); }
    return s;
}
int main(void) { return slice(); }
