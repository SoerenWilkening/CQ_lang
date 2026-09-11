/* p23 — the SHIPPED 1b accept: an INVARIANT bool in a classically-bounded loop. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; i++) if (b) cq_phi(0.7);
    return cq_measure(b);
}
