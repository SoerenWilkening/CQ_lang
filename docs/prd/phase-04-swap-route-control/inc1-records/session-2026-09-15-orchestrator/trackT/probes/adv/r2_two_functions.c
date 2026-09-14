/* R2-2 — bd `test_C_libtooling-1yeu`, the one-function-per-module instrument gap,
   attacked directly: TWO kernels in one TU, one of which qualifies for the new
   round-1 grant and one of which must not.  A per-function state leak in the
   grant record would mark the wrong loop. */
#include "CQ.h"
int ka(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) s += cq_measure((y >> k) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int kb(void) {
    int y = cq_theta(6, 0.4);
    int p = y * 3;                       /* hoisted TEMPLATE rail read as data */
    int s = 0;
    for (int k = 1; k <= 2; ++k) s += cq_measure((p >> k) & 1);
    return s + cq_measure(y);
}
int main(void) { return ka() + kb(); }
