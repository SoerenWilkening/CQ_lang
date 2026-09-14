#include "CQ.h"
/* p7 — a value that merges a phi-DEPENDENT and a phi-INDEPENDENT operand
   (brief item 1: which way does the transitive USER closure over-approximate?). */
int main(void) {
    bool q = cq_theta(0, 0.5);
    bool b1 = 0, b2 = 0;
    int a = 5, indep = 2;
    if (q) { b1 = cq_theta(b1, 0.5); }
    int mixed = b1 ? (a - 3) : indep;   /* one arm reads M, the other does not */
    if (mixed > 2) { b2 = cq_theta(b2, 0.5); }
    return cq_measure(b1)+cq_measure(b2)+cq_measure(mixed);
}
