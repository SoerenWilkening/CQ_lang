#include "CQ.h"
/* bd hn29 case (1), the spelling -O1 does NOT fuse: a different-condition
   kickback sits between the two readers of the prep phi, so the SECOND reader's
   Pred is two blocks past the phi's own block. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1) cq_phi(0.3);
    if (b0) cq_phi(0.4);
    if (b1) cq_phi(0.7);
    return cq_measure(b0) + cq_measure(b1);
}
