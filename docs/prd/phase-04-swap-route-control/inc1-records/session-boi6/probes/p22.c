/* p22 — the p5 shape with an INT register in place of the bool (the compare twin). */
#include "CQ.h"
int main(void) {
    int q = cq_theta(5, 0.2);
    int r = cq_theta(0, 0.4);
    if (q > 3) r = cq_theta(r, 0.9);
    if (r > 1) cq_phi(0.3);
    return cq_measure(q) + cq_measure(r);
}
