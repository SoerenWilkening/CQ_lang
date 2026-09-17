/* ATTACK A1 on the c1 conversion: ONE-OPERAND DELTA = a SECOND post-loop
   non-diagonal gate on the register the compare rails copy. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) s += cq_measure(y > k);
    y = cq_theta(y, 0.9);
    y = cq_theta(y, 0.3);            /* <-- the delta */
    return s + cq_measure(y);
}
int main(void) { return slice(); }
