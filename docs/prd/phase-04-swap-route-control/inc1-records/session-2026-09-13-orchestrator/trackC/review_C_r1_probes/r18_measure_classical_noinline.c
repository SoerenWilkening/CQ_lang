/* r18 — a CLASSICAL measure in a noinline callee, in a module that is otherwise quantum. */
#include "CQ.h"
__attribute__((noinline)) static int meas(int x) { return cq_measure(x); }
int main(void) {
    int q = cq_theta(3, 0.5);
    return cq_measure(q) + meas(7);
}
