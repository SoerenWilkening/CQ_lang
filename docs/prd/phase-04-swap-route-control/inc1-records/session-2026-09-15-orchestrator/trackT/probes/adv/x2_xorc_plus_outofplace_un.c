#include "CQ.h"
int slice(void) {
    volatile int v = 3;
    int y = cq_theta(5, 0.5);
    int z = cq_theta(7, 0.3);
    int s = 0;
    z ^= v; s += cq_measure((y >> 1) & 1);
    z ^= v; s += cq_measure((y >> 2) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y) + cq_measure(z);
}
int main(void) { return slice(); }
