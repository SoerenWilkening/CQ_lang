#include "CQ.h"
int slice(void) {
    int s = 0;
    { int u = cq_theta(5, 0.5); int r = cq_theta(7, 0.25); if ((u >> 1) & 1) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(u); }
    { int u = cq_theta(5, 0.5); int r = cq_theta(7, 0.25); if ((u >> 1) & 1) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(u); }
    return s;
}
int main(void) { return slice(); }
