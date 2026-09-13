/* r07 — item 1: measure a rail carried through a bounded loop with in-loop phase control. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 3; ++i) {
        b = cq_theta(b, 0.5);
        if (b) cq_phi(0.3);
    }
    return cq_measure(b);
}
