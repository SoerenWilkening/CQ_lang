#include "CQ.h"
/* bd hn29 case (1): two kickbacks on the SAME prep phi.  The first sits in the
   prep's own merge block; the SECOND's Pred is the first kickback's merge. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1) cq_phi(0.3);
    if (b1) cq_phi(0.7);
    return cq_measure(b0) + cq_measure(b1);
}
