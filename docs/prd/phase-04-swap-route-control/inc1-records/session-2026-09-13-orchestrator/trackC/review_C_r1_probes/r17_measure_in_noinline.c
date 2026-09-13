/* r17 — item 1: the measure lives in a NOINLINE callee (specialization/clone path). */
#include "CQ.h"
__attribute__((noinline)) static int meas(int x) { return cq_measure(x); }
int main(void) {
    int q = cq_theta(3, 0.5);
    return meas(q);
}
