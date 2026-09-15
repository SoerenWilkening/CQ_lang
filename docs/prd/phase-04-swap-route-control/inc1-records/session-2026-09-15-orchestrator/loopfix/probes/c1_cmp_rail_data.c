/* The program of `loop_leak_dephase_reject_cmp_rail_data.ll` (bd
   `test_C_libtooling-7845`).  Its own L8 retirement trigger named bd
   `test_C_libtooling-tu9q` as the end state that turns it into an ACCEPT whose
   stream is the twin's, rolled.  `tu9q` landed 2026-09-15; this re-derives it. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) s += cq_measure(y > k);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
