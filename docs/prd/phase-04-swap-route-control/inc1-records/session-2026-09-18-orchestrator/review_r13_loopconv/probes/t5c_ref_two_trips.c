/* The straight-line program `t5c_classical_break_taken.c` DENOTES at lim == 2 —
   exactly two trips, then the interference.  This is the break-path reference. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    s += cq_measure((y >> 1) & 1);
    s += cq_measure((y >> 2) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
