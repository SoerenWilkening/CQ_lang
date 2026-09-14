/* w_b twin — iteration-local state prep under a rail condition, K=2 unrolled. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int s = 0;
    { int r = 7; if (b) r = cq_theta(7, 0.2); s += cq_measure(r); }
    { int r = 7; if (b) r = cq_theta(7, 0.2); s += cq_measure(r); }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
