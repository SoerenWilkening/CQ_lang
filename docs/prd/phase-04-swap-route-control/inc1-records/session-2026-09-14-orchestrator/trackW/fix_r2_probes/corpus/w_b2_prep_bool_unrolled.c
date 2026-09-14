/* w_b2 twin — iteration-local state prep under a rail condition, K=2 unrolled,
   with the per-trip measurements pulled out so no value chain forms in the arm. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r0 = 7; if (b) r0 = cq_theta(7, 0.2);
    int r1 = 7; if (b) r1 = cq_theta(7, 0.2);
    return cq_measure(r0) + cq_measure(r1) + cq_measure(b);
}
int main(void) { return slice(); }
