#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0[3];
    if (a >= 3) { b0[0] = cq_theta(b0[0], 0.5); }
    if (b0[0]) a -= 3;
    if (a >= 3) { b0[1] = cq_theta(b0[1], 0.5); }
    if (b0[1]) a -= 3;
    if (a >= 3) { b0[2] = cq_theta(b0[2], 0.5); }
    if (b0[2]) a -= 3;
    return cq_measure(b0[0]) + cq_measure(b0[1])  + cq_measure(b0[2]) + cq_measure(a);
}
