/* R2-1 — a `break` loop (7.4) beside a loop-invariant root-mint read.  `tryBreak`
   runs FIRST in `lowerLoops` and `continue`s, so the new offer must never see a
   loop `tryBreak` claimed. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        s += cq_measure((y >> k) & 1);
        if (s > 1) break;
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
