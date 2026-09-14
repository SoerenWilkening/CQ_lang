/* the hand-unrolled N=2 twin with an OPAQUE seed for a, so -O1 cannot const-fold
   trip 0's condition — the honest byte-identity twin for the ROLLED array form. */
#include "CQ.h"
int slice(int a) {
    bool b[2] = {0};
    if (a >= 3) b[0] = cq_theta(b[0], 0.5);
    if (b[0]) a -= 3;
    if (a >= 3) b[1] = cq_theta(b[1], 0.5);
    if (b[1]) a -= 3;
    return cq_measure(a) + cq_measure(b[0]) + cq_measure(b[1]);
}
int main(void){ return slice(5); }
