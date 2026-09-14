#include "CQ.h"
int main(void) {
    int q = cq_theta(0, 0.7);
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1 && q > 3) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(q);
}
