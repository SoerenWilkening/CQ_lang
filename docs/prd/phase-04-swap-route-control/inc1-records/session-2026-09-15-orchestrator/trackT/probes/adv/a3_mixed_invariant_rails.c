/* ADV-3 — TWO loop-invariant tainted reads: one MEASURE-OWNED (admitted by
   clause (ii-c)) and one a genuine hoisted TEMPLATE rail read as data (must be
   refused).  If (ii-c) admitted the first and the loop were marked anyway, the
   second becomes the K-adjoints-vs-one-forward-gate multiplicity miscompile. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int p = y * 3;
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure(y & 1) + cq_measure((p >> k) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
