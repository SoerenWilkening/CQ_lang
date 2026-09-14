/* The same SIBLING shape in the RAIL-LEAF spelling (unconditional b1 prep), i.e.
   reachable on the FROZEN ORACLE with no Track M change at all — the control that
   says whether the hole is pre-existing. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    b1 = cq_theta(b1, 0.5);
    if (b1) a -= 3;
    bool c = cq_theta(b1, 0.25);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(c) + cq_measure(a);
}
