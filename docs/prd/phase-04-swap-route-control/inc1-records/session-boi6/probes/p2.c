/* p2 — the theta BEFORE the region in the body. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; i++) {
        b = cq_theta(b, 0.2);
        if (b) cq_phi(0.7);
    }
    return cq_measure(b);
}
