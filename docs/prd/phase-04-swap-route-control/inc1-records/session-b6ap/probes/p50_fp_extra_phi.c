/* (7) 2-phi merge whose extra phi is a DOUBLE */
#include "CQ.h"
int main(void) {
    int b0 = cq_theta(0, 0.5); int b1 = 0; double d = 1.5;
    if (b0 == 1) d = 2.5;
    if (b0 != 1) b1 = cq_theta(b1, 0.5);
    return cq_measure(b0) + cq_measure(b1) + (int)d;
}
