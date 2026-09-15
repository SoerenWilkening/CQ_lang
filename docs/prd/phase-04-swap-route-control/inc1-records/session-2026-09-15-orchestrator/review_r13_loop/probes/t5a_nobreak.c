/* R13-r2 T-5 WITNESS (a): r1_break_loop with the `break` REMOVED — same body,
   same four trips, and a hand-unrolled twin that does NOT trip bd 3d8q. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k)
        s += cq_measure((y >> k) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
