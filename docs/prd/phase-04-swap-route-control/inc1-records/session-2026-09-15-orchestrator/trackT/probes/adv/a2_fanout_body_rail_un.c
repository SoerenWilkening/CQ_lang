#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    { int t = y >> 1; s += cq_measure(t & 1) + cq_measure(t & 2); }
    { int t = y >> 2; s += cq_measure(t & 1) + cq_measure(t & 2); }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
