#include "CQ.h"
/* the phi leaf CONJOINED WITH THE PREP'S OWN CONTROL REGISTER.  Post-M-beta the
   prep is cqrt_ry_i1_controlled(h_b0, h_b1, t) and the kickback then reads BOTH
   h_b1 and h_b0 as toffoli controls.  Is the wire fence asked about b0's role as
   the prep's control? */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1 && b0) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1);
}
