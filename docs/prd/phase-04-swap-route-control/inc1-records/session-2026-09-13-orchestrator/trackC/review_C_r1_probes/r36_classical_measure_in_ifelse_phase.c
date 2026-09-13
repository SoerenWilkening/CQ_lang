/* r36 — a classical measure in the ELSE arm of a phase if/else. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int c = 9;
    if (q == 3) { cq_phi(0.3); } else { (void)cq_measure(c); }
    return cq_measure(q);
}
