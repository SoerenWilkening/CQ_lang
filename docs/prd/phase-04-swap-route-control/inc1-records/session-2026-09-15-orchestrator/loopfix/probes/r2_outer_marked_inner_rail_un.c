/* twin: the INNER loop hand-unrolled, the outer left rolled. */
#include "CQ.h"
int slice(void) {
    int s = 0;
    for (int i = 0; i < 2; ++i) {
        int w = cq_theta(7, 0.3);
        s += cq_measure((w >> 1) & 1);
        s += cq_measure((w >> 2) & 1);
        w = cq_theta(w, 0.9);
        s += cq_measure(w);
    }
    return s;
}
int main(void) { return slice(); }
