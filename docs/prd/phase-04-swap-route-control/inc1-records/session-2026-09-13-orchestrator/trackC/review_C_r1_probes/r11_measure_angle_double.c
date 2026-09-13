/* r11 — item 2/3: a classical double (a rotation ANGLE) measured. Must NOT mint a rail. */
#include "CQ.h"
int main(void) {
    double th = 0.5;
    int q = cq_theta(3, th);
    return cq_measure(q) + (int)cq_measure(th);
}
