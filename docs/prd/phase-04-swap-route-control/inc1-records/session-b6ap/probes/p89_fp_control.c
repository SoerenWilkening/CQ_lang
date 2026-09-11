/* CONTROL for h87: the same prep region with NO fp mux at all */
#include "CQ.h"
int main(void) {
    double p = cq_theta(0.0, 0.3);
    int b0 = cq_theta(0, 0.5);
    int b1 = 0;
    if (b0 != 1) b1 = cq_theta(b1, 0.5);
    return cq_measure(b0) + cq_measure(b1) + (int)cq_measure(p);
}
