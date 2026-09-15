/* X8 + the interference Rule 8 names. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1) + cq_measure((y >> 3) & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
