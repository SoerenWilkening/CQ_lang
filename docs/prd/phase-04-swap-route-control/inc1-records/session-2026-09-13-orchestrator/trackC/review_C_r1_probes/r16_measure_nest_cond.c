/* r16 — the inner condition of a depth-2 nest, measured. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int p = cq_theta(2, 0.25);
    bool ci = (p == 2);
    if (q == 3) { if (ci) cq_phi(0.7); }
    return cq_measure(ci);
}
