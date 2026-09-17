/* What t5h denotes at lim == 2: trip 1 full (both uses), trip 2 breaks after use 1. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    { int d = (y >> 1); s += cq_measure(d & 1); s += cq_measure(d & 2); }
    { int d = (y >> 2); s += cq_measure(d & 1); }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
