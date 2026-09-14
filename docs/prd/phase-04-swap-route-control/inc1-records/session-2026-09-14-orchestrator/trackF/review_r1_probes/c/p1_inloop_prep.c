#include "CQ.h"
/* p1 — an in-loop STATE PREP. Does it reach F2 at all?  The only SSA-legal hole
   in the availability argument is a loop-carried phi that takes the region's
   merge phi on the BACK EDGE: such a phi IS available at the arm (the header
   dominates the body) yet IS in the transitive user closure of M. */
int main(void) {
    int a = 5;
    int s = 0;
    for (int i = 0; i < 3; i++) {
        bool b = 0;
        if (a >= 3) { b = cq_theta(b, 0.5); }
        s += cq_measure(b);
        a -= 1;
    }
    return s;
}
