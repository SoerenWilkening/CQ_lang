#include "CQ.h"
int main(void) {
    int b0 = 0;
    int b1 = 7;
    int a = 5;
    b0 = cq_theta(b0, 0.5);
    if (b0 == 1) { b1 = cq_theta(7, 0.5); a = 2; }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
