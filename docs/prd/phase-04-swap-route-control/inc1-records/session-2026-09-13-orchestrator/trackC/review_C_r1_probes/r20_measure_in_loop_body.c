/* r20 — item 4: a classical measure inside a bounded loop body under quantum control. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.0);
    int c = 9, s = 0;
    for (int i = 0; i < 3; ++i) {
        b = cq_theta(b, 0.5);
        if (b) { cq_phi(0.3); }
        s += cq_measure(c);
    }
    return s + cq_measure(b);
}
