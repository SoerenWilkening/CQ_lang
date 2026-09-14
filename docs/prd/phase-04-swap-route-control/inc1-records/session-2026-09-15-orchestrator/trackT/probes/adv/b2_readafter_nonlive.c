/* ADV-B2 — the other half of the (ii-c) boundary, again independent of the s82e
   fence: the invariant rail is measured INSIDE the loop and ALSO read as DATA
   after it, so it is NOT measure-owned.  Must accept and still leak. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int b = y & 1;
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure(b) + cq_measure((y >> k) & 1);
    return s + cq_measure(b + 1) + cq_measure(y);
}
int main(void) { return slice(); }
