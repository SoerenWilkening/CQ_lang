/* w_d twin — iteration-local rotated base under a rail condition, K=2 unrolled. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int s = 0;
    { int r = cq_theta(7, 0.25); if (b) r = cq_theta(r, 0.2); s += cq_measure(r); }
    { int r = cq_theta(7, 0.25); if (b) r = cq_theta(r, 0.2); s += cq_measure(r); }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
