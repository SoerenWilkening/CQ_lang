/* Track beta P2 — the leaked rail copies a register that is re-rotated INSIDE
   the loop and nowhere after it. Conjunct (2) requires the chained theta to be
   OUTSIDE `L`, so `Rots` is empty. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) {
        s += cq_measure((y >> k) & 1);
        y = cq_theta(y, 0.1);      /* the interference, INSIDE the loop */
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
