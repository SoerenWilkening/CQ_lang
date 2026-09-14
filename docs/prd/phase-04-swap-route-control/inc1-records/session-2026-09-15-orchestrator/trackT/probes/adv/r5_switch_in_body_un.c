#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    { int u = cq_theta(6, 0.4); if ((y >> 1) & 1) cq_phi(0.3); s += cq_measure(u); }
    { int u = cq_theta(6, 0.4); if ((y >> 2) & 1) cq_phi(0.3); s += cq_measure(u); }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
