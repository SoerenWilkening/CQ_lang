/* twin: the OUTER loop hand-unrolled, the inner left rolled. */
#include "CQ.h"
int slice(void) {
    int s = 0;
    int y = cq_theta(5, 0.5);
    s += cq_measure((y >> 1) & 1);
    for (int j = 0; j < 2; ++j) { int u = cq_theta(6, 0.4); s += cq_measure((u >> j) & 1); }
    y = cq_theta(y, 0.9);
    s += cq_measure((y >> 2) & 1);
    for (int j = 0; j < 2; ++j) { int u = cq_theta(6, 0.4); s += cq_measure((u >> j) & 1); }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
