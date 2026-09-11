/* 2 phis, BOTH arm-defined CALLS (two state preps in one arm) — NOT peelable */
#include "CQ.h"
int main(void) {
    int b0 = cq_theta(0, 0.5);
    int b1 = 0; int b2 = 0;
    if (b0 > 3) { b1 = cq_theta(b1, 0.5); b2 = cq_theta(b2, 0.9); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2);
}
