#include "CQ.h"
/* F x P with TWO prep merge phis as the two tree leaves (neither is the other's
   control).  4aiu records that at the KICKBACK at most ONE phi leaf can satisfy
   the in-Pred requirement; this asks what happens when two are offered. */
int main(void) {
    bool g = cq_theta((bool)0, 0.5);
    bool b0 = 0;
    bool b1 = 0;
    if (g) { b0 = cq_theta(b0, 0.5); }
    if (g) { b1 = cq_theta(b1, 0.5); }
    if (b1 && b0) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(g);
}
