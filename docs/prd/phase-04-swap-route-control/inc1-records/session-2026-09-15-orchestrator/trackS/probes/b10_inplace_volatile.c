/* Track beta P10 — the IN-PLACE OVER-DECLINE question (IMPL_S §16.3), with
   conjunct (2) ACTUALLY SATISFIED this time: a CONSTANT trip count so the loop
   is unguarded and the header dominates the post-loop rotation, and a volatile
   operand so `-O1` cannot fold the in-place chain away. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    volatile int v = 1;
    for (int k = 0; k < 3; ++k)
        y ^= v;                    /* in-place: relabels the rail, mints nothing */
    y = cq_theta(y, 0.9);
    return cq_measure(y);
}
int main(void) { return slice(); }
