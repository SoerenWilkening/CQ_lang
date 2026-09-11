/* p33 — a SIBLING theta on the carried rail inside the body (F-1b-1's class, rolled). */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; i++) {
        bool c = cq_theta(b, 0.9);
        if (b) cq_phi(0.7);
        acc += cq_measure(c);
        b = cq_theta(b, 0.2);
    }
    return acc + cq_measure(b);
}
