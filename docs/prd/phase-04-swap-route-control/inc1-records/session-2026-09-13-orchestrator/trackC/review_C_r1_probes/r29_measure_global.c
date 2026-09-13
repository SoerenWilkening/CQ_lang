/* r29 — a classical GLOBAL measured inside a quantum module. */
#include "CQ.h"
static int g = 11;
int main(void) {
    int q = cq_theta(3, 0.5);
    return cq_measure(g) + cq_measure(q);
}
