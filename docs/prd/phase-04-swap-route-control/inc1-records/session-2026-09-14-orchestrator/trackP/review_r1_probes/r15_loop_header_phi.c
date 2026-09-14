#include "CQ.h"
/* bd boi6's loop-carried _Bool header phi: an UNCLAIMED 2-incoming i1 phi at a
   phase kickback.  Must keep `branch phase on a bare i1 condition` AND a real
   source location (this is the exact F-P2 regression class). */
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; ++i) {
        if (b) cq_phi(0.3);
        b = !b;
    }
    return cq_measure(b);
}
