/* r30 — item 5 (L1): a value DERIVED from a 6.5 %out (round-2 taint), measured. */
#include "CQ.h"
static int f(int x) { return x + 1; }
int main(void) {
    int a = 5;
    bool b = cq_theta((bool)0, 0.5);
    int y = 0;
    if (b) y = f(a);
    int z = y + 2;
    return cq_measure(z) + cq_measure(b);
}
