/* ADV-6 — trip count 1: the degenerate case of the rolled form. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 1; ++k)
        s += cq_measure((y >> k) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
