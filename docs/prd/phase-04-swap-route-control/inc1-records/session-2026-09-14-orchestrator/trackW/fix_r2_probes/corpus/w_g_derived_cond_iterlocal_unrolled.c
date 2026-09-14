#include "CQ.h"
int slice(void) {
    int q = cq_theta(5, 0.5);
    int s = 0;
    { int r = cq_theta(7, 0.25); if ((q >> 0) & 1) r = cq_theta(r, 0.2); s += cq_measure(r); }
    { int r = cq_theta(7, 0.25); if ((q >> 1) & 1) r = cq_theta(r, 0.2); s += cq_measure(r); }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
