/* R2-C'' — the SAME body with a COMPARE condition (the shipped drbq Inc-3
   `control_inplace_ry_inloop_offset.ll` shape), so the ORACLE accepts it and the
   in-place-vs-out-of-place twin divergence can be dated. */
#include "CQ.h"
int slice(void) {
    int  q = cq_theta(5, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        if (q == 5) r = cq_theta(r, 0.9);
        q = q + 3;
        s += cq_measure(q);
    }
    return s + cq_measure(r);
}
int main(void) { return slice(); }
