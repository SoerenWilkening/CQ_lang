/* R2-J — mutation control for `control_inplace_ry_reject_inloop_iterlocal_twofn.ll`:
   the SAME two-kernel module shape with BOTH kernels of the PASSING kind.  If
   this declined, the fixture would be pinning "two kernels", not "the second
   kernel's conjunct 2". */
#include "CQ.h"
int kernel_a(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        bool t = cq_theta((bool)0, 0.5); int r = cq_theta(7, 0.25);
        if (t) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(t);
    }
    return s;
}
int kernel_b(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        bool t = cq_theta((bool)0, 0.6); int r = cq_theta(9, 0.35);
        if (t) r = cq_theta(r, 0.3);
        s += cq_measure(r) + cq_measure(t);
    }
    return s;
}
int main(void) { return kernel_a() + kernel_b(); }
