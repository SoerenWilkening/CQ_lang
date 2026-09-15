#include "CQ.h"
int slice(void) {
    int b0 = 0, b1 = 0, b2 = 0;
    b0 = cq_theta(b0, 0.5);
    b1 = cq_theta(b1, 0.5);
    b2 = cq_theta(b2, 0.5);
    int q = cq_theta(0, 0.3);
    q = cq_theta(q, 0.7);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2) + cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
