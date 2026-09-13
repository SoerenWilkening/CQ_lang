/* r35 — a classical measure beside a classical call in a 6.5 arm. */
#include "CQ.h"
static int f(int x) { return x + 1; }
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int c = 9, y = 0;
    if (b) { y = f(c) + cq_measure(c); }
    return y + cq_measure(b);
}
