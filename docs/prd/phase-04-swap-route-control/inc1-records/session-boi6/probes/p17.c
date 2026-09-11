/* p17 — ITERATION-LOCAL bool minted in the body (no rail phi). */
#include "CQ.h"
int main(void) {
    int acc = 0;
    for (int i = 0; i < 3; i++) {
        bool t = cq_theta((bool)0, 0.5);
        if (t) cq_phi(0.7);
        acc += cq_measure(t);
    }
    return acc;
}
