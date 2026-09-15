/* Track T — the BENIGN control for s1: the identical rolled shape with NO
   post-loop rotation of `y`.  On the ORACLE it ACCEPTS and LEAKS (Rule-6
   accepted leak, `declineDephasingUnmarkedLoopRails` conjunct (2) empty); with
   the pairing it must ACCEPT and DISCHARGE, byte-identical to its twin. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure((y >> k) & 1);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
