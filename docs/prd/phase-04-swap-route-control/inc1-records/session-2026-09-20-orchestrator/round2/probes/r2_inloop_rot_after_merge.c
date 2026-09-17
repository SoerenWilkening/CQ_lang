/* r2: a NON-DIAGONAL gate INSIDE the loop, on the merge rail, after the merge.
   The previous register and the arm's `a-3` chain rail are still alive and
   entangled with it -- the Rule-8 shape, one trip earlier than r1. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    int c = 0;
    for (int i = 0; i < 3; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
        c = cq_theta(a, 0.2);      /* chained Ry on the carried register */
    }
    return cq_measure(c);
}
int main(void) { (void) run(); return 0; }
