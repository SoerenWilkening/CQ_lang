/* the fused diamond's condition is an AND with the rail as a LEAF, beside a peel */
#include "CQ.h"
int main(void) {
    int q = cq_theta(0, 0.3);
    bool b0 = cq_theta((bool)0, 0.5);
    int a = 5; int z = 1; bool b1 = 0;
    if (b0 && q > 2) { a -= 3; z = 4; b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0)+cq_measure(b1)+cq_measure(a)+cq_measure(z)+cq_measure(q);
}
