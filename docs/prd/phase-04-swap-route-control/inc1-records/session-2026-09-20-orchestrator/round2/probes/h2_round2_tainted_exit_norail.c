/* h2: the CONTROL for h1 -- same quantum-derived bound, no carried handle in the
   loop at all, so nothing of bd `zujr`'s is involved. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    bool c = cq_theta((bool)0, 0.5);
    int n = 2;
    if (c) n = 3;
    int s = 0;
    for (int i = 0; i < n; ++i) s += i;
    return cq_measure(c) + s;
}
int main(void) { (void) run(); return 0; }
