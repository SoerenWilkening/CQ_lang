/* r01 — item 1: measure the %out of a 6.5 classical-call arm (round-2 taint). MUST emit cqrt_measure. */
#include "CQ.h"
static int f(int x) { return x + 1; }
int main(void) {
    int a = 5;
    bool b = cq_theta((bool)0, 0.5);
    int y = 0;
    if (b) y = f(a);
    return cq_measure(y) + cq_measure(b);
}
