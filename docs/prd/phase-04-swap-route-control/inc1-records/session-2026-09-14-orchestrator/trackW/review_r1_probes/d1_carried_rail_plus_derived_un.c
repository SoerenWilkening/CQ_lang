#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(7, 0.25);
    int s = 0;
    { int u = cq_theta(5, 0.5); if ((u >> 1) & 1) r = cq_theta(r, 0.2); if (b) r = cq_theta(r, 0.3); s += cq_measure(u); }
    { int u = cq_theta(5, 0.5); if ((u >> 1) & 1) r = cq_theta(r, 0.2); if (b) r = cq_theta(r, 0.3); s += cq_measure(u); }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
