#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int z = cq_theta(6, 0.4);
    int s = 0;
    s += cq_measure(((y >> 1) & 1) + ((z >> 1) & 1));
    s += cq_measure(((y >> 2) & 1) + ((z >> 2) & 1));
    y = cq_theta(y, 0.9);
    z = cq_theta(z, 0.7);
    return s + cq_measure(y) + cq_measure(z);
}
int main(void) { return slice(); }
