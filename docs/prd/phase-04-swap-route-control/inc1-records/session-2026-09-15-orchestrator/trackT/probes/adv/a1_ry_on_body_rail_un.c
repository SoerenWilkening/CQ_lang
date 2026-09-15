#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    { int t = (y >> 1) & 1; t = cq_theta(t, 0.2); s += cq_measure(t); }
    { int t = (y >> 2) & 1; t = cq_theta(t, 0.2); s += cq_measure(t); }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
