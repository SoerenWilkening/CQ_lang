/* twin: the MIDDLE loop hand-unrolled; outer and inner left rolled. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 0; i < 2; ++i) {
        s += cq_measure((y >> 1) & 1);
        for (int k = 0; k < 2; ++k) { int u = cq_theta(6, 0.4); s += cq_measure((u >> k) & 1); }
        s += cq_measure((y >> 2) & 1);
        for (int k = 0; k < 2; ++k) { int u = cq_theta(6, 0.4); s += cq_measure((u >> k) & 1); }
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
