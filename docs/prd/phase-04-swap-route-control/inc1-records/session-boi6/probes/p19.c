/* p19 — measure the carried bool BEFORE the region in the body. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; i++) {
        acc += cq_measure(b);
        if (b) cq_phi(0.7);
        b = cq_theta(b, 0.2);
    }
    return acc;
}
