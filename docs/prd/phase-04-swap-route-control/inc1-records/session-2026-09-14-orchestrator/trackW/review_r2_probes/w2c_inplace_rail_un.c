/* hand-unrolled twin of w2c_inplace_rail (K=2) */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  q = cq_theta(5, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    { if (b) r = cq_theta(r, 0.3); q = q + 3; s += cq_measure(q); }
    { if (b) r = cq_theta(r, 0.3); q = q + 3; s += cq_measure(q); }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
