/* p7 — measure the carried bool INSIDE the body (must decline). */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; i++) {
        if (b) cq_phi(0.7);
        acc += cq_measure(b);
        b = cq_theta(b, 0.2);
    }
    return acc;
}
