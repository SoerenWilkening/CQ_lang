/* Item 2 — the plain-C customer of rung 0's `RailLadderProven` conjunct: the prep
   region's condition is a COMPARE over an `int` register, and the merge block
   carries a SINGLE phi (no a-mux), so MergePhiPeel does not run and F2/rb9x
   cannot fire. */
#include "CQ.h"
int main(void) {
    int a = 5;
    int b0 = cq_theta(0, 0.5);
    bool b1 = 0;
    if (b0 == 1) b1 = cq_theta(b1, 0.5);
    if (b1) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
