/* p5 — a bool produced by a preceding CONTROLLED-Ry region, read by the next region. */
#include "CQ.h"
int main(void) {
    int  q = cq_theta(5, 0.2);
    bool b = cq_theta((bool)0, 0.4);
    if (q > 3) b = cq_theta(b, 0.9);
    if (b) cq_phi(0.3);
    return cq_measure(q) + cq_measure(b);
}
