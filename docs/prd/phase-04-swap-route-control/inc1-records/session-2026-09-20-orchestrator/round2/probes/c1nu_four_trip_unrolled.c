/* c1nu: the 4-activation hand-unrolled twin of c1 with the break never taken. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    { bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; }
    { bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; }
    { bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; }
    { bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; }
    return cq_measure(a);
}
int main(void) { (void) run(); return 0; }
