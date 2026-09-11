/* 2 phis, BOTH arm-defined, arm NOT speculatable (has a theta) */
#include "CQ.h"
int main(void) {
    int b0 = cq_theta(0, 0.5);
    int r = b0 + 1; int s = 0; int b1 = 0;
    if (b0 == 1) { b1 = cq_theta(b1, 0.5); s = r + 7; }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(s);
}
