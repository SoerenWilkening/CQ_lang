/* r28 — a classical value loaded from a volatile local, measured. */
#include "CQ.h"
int main(void) {
    volatile int v = 7;
    int q = cq_theta(3, 0.5);
    int r = v;
    return cq_measure(r) + cq_measure(q);
}
