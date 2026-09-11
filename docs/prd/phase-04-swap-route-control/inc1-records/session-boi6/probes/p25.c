/* p25 — TWO independent carried bools, a region on each. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    bool c = cq_theta((bool)1, 0.3);
    for (int i = 0; i < 3; i++) {
        if (b) cq_phi(0.7);
        if (c) cq_phi(0.9);
        b = cq_theta(b, 0.2);
        c = cq_theta(c, 0.4);
    }
    return cq_measure(b) + cq_measure(c);
}
