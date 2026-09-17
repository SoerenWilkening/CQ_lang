/* twin: the OUTER loop hand-unrolled, the inner (c1's own) left rolled. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) s += cq_measure(y > k);
    for (int k = 1; k <= 2; ++k) s += cq_measure(y > k);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
