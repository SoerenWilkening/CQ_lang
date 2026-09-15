/* twin: the SECOND (y-copying) loop hand-unrolled, the first left rolled. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 0; i < 2; ++i) { int u = cq_theta(6, 0.4); s += cq_measure((u >> i) & 1); }
    s += cq_measure((y >> 1) & 1);
    s += cq_measure((y >> 2) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
