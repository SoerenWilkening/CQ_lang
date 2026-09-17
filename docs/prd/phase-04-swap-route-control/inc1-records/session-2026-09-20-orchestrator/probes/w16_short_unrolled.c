#include "CQ.h"
int main(void) {
    short acc = 0;
    bool b0[3];
    b0[0] = cq_theta(b0[0], 0.5);
    if (b0[0]) acc = 1;
    b0[1] = cq_theta(b0[1], 0.5);
    if (b0[1]) acc = 1;
    b0[2] = cq_theta(b0[2], 0.5);
    if (b0[2]) acc = 1;
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + (int)cq_measure(acc);
}
