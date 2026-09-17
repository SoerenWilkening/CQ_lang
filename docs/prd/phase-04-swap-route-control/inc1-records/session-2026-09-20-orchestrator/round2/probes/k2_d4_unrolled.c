/* k2: the hand-unrolled twin of d4 (condition reads the carried register, no
   trailing gate) -- the rolled-vs-unrolled instrument for the accepting case. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    { bool b = 0; if (a >= 3) b = cq_theta(b, 0.5); if (b) a -= 3; }
    { bool b = 0; if (a >= 3) b = cq_theta(b, 0.5); if (b) a -= 3; }
    { bool b = 0; if (a >= 3) b = cq_theta(b, 0.5); if (b) a -= 3; }
    return cq_measure(a);
}
int main(void) { (void) run(); return 0; }
