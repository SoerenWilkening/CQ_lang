/* R2-3 — TWO loops reading the SAME loop-invariant root mint.  The grant record
   is keyed on the loop HEADER; a module-scoped key would let one loop's grant
   satisfy the other's re-ask (the F-C1B-2 / F-W1-1 shape). */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) s += cq_measure((y >> k) & 1);
    for (int k = 3; k <= 4; ++k) s += cq_measure((y >> k) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
