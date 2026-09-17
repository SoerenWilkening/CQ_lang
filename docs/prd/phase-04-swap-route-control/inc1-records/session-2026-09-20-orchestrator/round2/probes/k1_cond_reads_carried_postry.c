/* k1: the carried PROTOCOL item (Rule 19 / session-2026-09-18 G-13) -- "an
   accept-direction widening of a CONDITION fence owes one rolled-vs-unrolled
   probe with a trailing non-diagonal gate on every register the condition reads."
   The condition reads the CARRIED register; a trailing `cq_theta` follows. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    for (int i = 0; i < 3; ++i) {
        bool b = 0;
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    a = cq_theta(a, -0.5);
    return cq_measure(a);
}
int main(void) { (void) run(); return 0; }
