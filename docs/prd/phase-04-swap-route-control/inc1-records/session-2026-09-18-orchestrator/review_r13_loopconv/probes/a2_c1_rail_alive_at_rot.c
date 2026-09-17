/* ATTACK A2 on the c1 conversion: ONE-OPERAND DELTA = the compare rail is NOT
   measured in the body.  It accumulates into `s`, so a COHERENT which-path
   record of `y` is alive when the post-loop non-diagonal gate fires on `y`.
   This is the Rule-8 hazard in its live form. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) s += (y > k);     /* <-- the delta: no cq_measure */
    y = cq_theta(y, 0.9);
    return cq_measure(s) + cq_measure(y);
}
int main(void) { return slice(); }
