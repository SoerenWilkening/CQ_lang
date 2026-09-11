/* p14 — a merge phi whose arm incoming is a FRESH rail (controlled state prep). */
#include "CQ.h"
int main(void) {
    int  q = cq_theta(5, 0.2);
    bool b = (bool)0;
    if (q > 3) b = cq_theta((bool)0, 0.9);
    if (b) cq_phi(0.3);
    return cq_measure(q) + cq_measure(b);
}
