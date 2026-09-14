#include "CQ.h"
/* p3 — BOUNDING PROBE (not about the conjunct): the rival register computed
   INSIDE the arm, where GVN's propagateEquality really does fold it to the seed.
   If both binaries accept, F2's blind spot here is PRE-EXISTING. */
int main(void) {
    int q = cq_theta(0, 0.3);
    int r = 0;
    if (q == -7) { int w = q + 7; r = cq_theta(w, 0.5); }
    return cq_measure(r) + cq_measure(q);
}
