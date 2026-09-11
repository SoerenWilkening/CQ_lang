/* p12 — a merge phi over TWO DISTINCT rails (no-cloning mux): must decline. */
#include "CQ.h"
int main(void) {
    int  q  = cq_theta(5, 0.2);
    bool b0 = cq_theta((bool)0, 0.4);
    bool b1 = cq_theta((bool)1, 0.6);
    bool b  = (q > 3) ? b0 : b1;
    if (b) cq_phi(0.3);
    return cq_measure(q) + cq_measure(b0) + cq_measure(b1);
}
