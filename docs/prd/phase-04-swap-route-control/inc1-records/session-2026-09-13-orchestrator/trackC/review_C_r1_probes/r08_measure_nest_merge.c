/* r08 — item 1: measure the merge phi of a depth-2 nest (RegionFlatten RAUW to q). */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int p = cq_theta(2, 0.25);
    if (q == 3) { if (p == 2) { cq_phi(0.7); } }
    return cq_measure(q) + cq_measure(p);
}
