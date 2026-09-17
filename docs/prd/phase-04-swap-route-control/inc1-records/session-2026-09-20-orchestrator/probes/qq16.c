#include "CQ.h"
int main(void) {
    short a = 0, b = 0;
    bool q[3];
    for (int i = 0; i < 3; ++i) {
        q[i] = cq_theta(q[i], 0.5);
        if (a == b) q[i] = cq_theta(q[i], 0.25);
        if (q[i]) a = 1;
        if (q[i]) b = 2;
    }
    return cq_measure(q[0]) + (int)cq_measure(a) + (int)cq_measure(b);
}
