/* r14 — same, value arm. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int a = 2;
    bool c = (q == 3);
    if (c) a = 5;
    return cq_measure(a) + cq_measure(c);
}
