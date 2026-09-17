/* h3c: the CONTROL -- the same program with a CLASSICAL bound. */
#include "CQ.h"
__attribute__((noinline))
int run(int seed, int k) {
    bool c = cq_theta((bool)0, 0.5);
    int n = 2;
    if (k) n = 3;
    int q = cq_theta(seed, 0.25);
    for (int i = 0; i < n; ++i)
        q = q ^ 5;
    return cq_measure(q) + cq_measure(c);
}
int main(void) { (void) run(3, 1); return 0; }
