/* ADV-4 — the invariant rail is measured INSIDE the loop and ALSO read as data
   AFTER it, so it is NOT measure-owned and (ii-c) must refuse. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int b = y & 1;
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure(b) + cq_measure((y >> k) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(b + 1) + cq_measure(y);
}
int main(void) { return slice(); }
