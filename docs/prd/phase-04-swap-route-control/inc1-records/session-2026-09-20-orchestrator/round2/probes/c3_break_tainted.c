/* c3: carried handle + TAINTED (7.4) value-arm break on a separate rail. */
#include "CQ.h"
__attribute__((noinline))
int run(int seed) {
    int a = 5;
    int q = cq_theta(seed, 0.25);
    for (int i = 0; i < 4; ++i) {
        q = q ^ 5;
        if (q == 7) break;
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a) + cq_measure(q);
}
int main(void) { (void) run(3); return 0; }
