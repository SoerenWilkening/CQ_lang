/* twin of N2: the OUTER loop hand-unrolled, the inner loop left rolled. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    s += cq_measure((y >> 1) & 1);
    for (int j = 0; j < 2; ++j) s += cq_measure((y >> (j + 8)) & 1);
    s += cq_measure((y >> 2) & 1);
    for (int j = 0; j < 2; ++j) s += cq_measure((y >> (j + 8)) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
