/* r12 — item 3: a classical phi with one uninitialized incoming (undef reaches the measure). */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int u;
    if (q == 3) u = 4;
    return cq_measure(u) + cq_measure(q);
}
