/* Track beta P3 — conjunct (2) matches the CALLEE NAME `cq_theta_*`.  Is the
   post-loop non-diagonal gate still spelled as a `@cq_theta_*` call at this
   slot, or has a region emitter already turned it into
   `cqrt_ry_<W>_controlled`?  If the latter, conjunct (2) misses it. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int b = cq_theta(0, 0.3);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure((y >> k) & 1);
    if (b) y = cq_theta(y, 0.9);      /* in-place CONTROLLED Ry arm, after the loop */
    return s + cq_measure(y) + cq_measure(b);
}
int main(void) { return slice(); }
