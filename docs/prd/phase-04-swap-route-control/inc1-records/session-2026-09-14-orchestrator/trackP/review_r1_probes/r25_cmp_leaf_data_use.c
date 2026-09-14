#include "CQ.h"
/* the COMPARE-leaf twin of r08: a TREE leaf with a use outside the branch.
   The step-6 TreeSet fence covers Tree.Leaves, so this must decline
   `condition used outside the branch` -- the asymmetry a phi leaf escapes. */
int main(void) {
    int q = cq_theta(0, 0.7);
    int r = cq_theta(0, 0.9);
    int z = 0;
    if (q > 3 && r > 5) cq_phi(0.3);
    if (q > 3) z = 1;
    return cq_measure(q) + cq_measure(r) + cq_measure(z);
}
