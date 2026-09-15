#include "CQ.h"
int slice(void) {
    _Bool b0 = 0, b1 = 0, b2 = 0;
    b0 = cq_theta(b0, 0.5);
    b1 = cq_theta(b1, 0.5);
    b2 = cq_theta(b2, 0.5);
    return (int) cq_measure(b0) + (int) cq_measure(b1) + (int) cq_measure(b2);
}
int main(void) { (void) slice(); return 0; }
