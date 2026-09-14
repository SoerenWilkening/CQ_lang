#include "CQ.h"
/* Rule 7 at the phi ROOT with BOTH polarities: the negated arm MUST be the
   diagonal rz(h,-theta), NEVER a cqrt_x bracket on the user's register. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1) cq_phi(0.3); else cq_phi(0.7);
    return cq_measure(b0) + cq_measure(b1);
}
