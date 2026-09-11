/* p10 — a carried bool as a LEAF of a condition TREE inside a loop. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  q = cq_theta(5, 0.2);
    for (int i = 0; i < 3; i++) { if (b && q == 5) cq_phi(0.7); b = cq_theta(b, 0.2); }
    return cq_measure(b) + cq_measure(q);
}
