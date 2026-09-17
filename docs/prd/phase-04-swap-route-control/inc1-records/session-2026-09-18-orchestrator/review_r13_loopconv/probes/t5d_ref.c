/* What t5d denotes at lim == 2: trip 1 runs the WHOLE body, trip 2 breaks after
   the first group. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    s += cq_measure((y >> 1) & 1);
    s += cq_measure((y >> 9) & 1);
    s += cq_measure((y >> 17) & 1);
    s += cq_measure((y >> 2) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
