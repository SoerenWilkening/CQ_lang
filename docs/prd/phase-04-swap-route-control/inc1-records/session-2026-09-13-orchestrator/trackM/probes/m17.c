#include "CQ.h"
#include <math.h>
/* T1 in plain C: the b1 prep is UNCONDITIONAL, so `-O1` leaves the select's
   condition as a bare `cq_theta_i1` CALL — byte-for-byte the value
   `emitInPlaceRotationRegion`'s M-beta RAUWs the owner file's merge phi to. */
int main(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    b1 = cq_theta(b1, 0.5);
    if (b1) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
