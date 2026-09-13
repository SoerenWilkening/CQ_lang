/* vd.c with the THIRD region's guard written `a >= -5` (always true at -O1's
   range for `a`): the downstream compare can no longer be pinned to FALSE. */
#include "CQ.h"
#include <math.h>
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0; bool b2 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    if (a >= -5){ b2 = cq_theta(b2, 0.5); }
    if (b2) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2) + cq_measure(a);
}
