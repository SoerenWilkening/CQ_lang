/* l1: L2 on the (L3) bank exemption.  A bank cell written on trip i and READ on
   trip i+1 crosses iterations through MEMORY, with no header phi for
   `railLocalQualifies`' clause (i) to see.  If the loop is marked
   ITERATION-LOCAL the spine may discharge that rail in-body. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0[4];
    b0[0] = cq_theta(b0[0], 0.5);
    for (int i = 1; i < 4; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i-1]) a -= 3;
    }
    return cq_measure(a) + cq_measure(b0[3]);
}
