#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int p = y * 3;
    int s = 0;
    s += cq_measure(y & 1) + cq_measure((p >> 1) & 1);
    s += cq_measure(y & 1) + cq_measure((p >> 2) & 1);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
