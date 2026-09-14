/* opaque seed, RUN-TIME select arms (a-3 vs a) — the L13 shape, minimal */
#include "CQ.h"
__attribute__((noinline)) int slice(int a) {
    bool b0 = 0;
    if (a >= 3) b0 = cq_theta(b0, 0.5);
    int r = b0 ? a - 3 : a;
    return cq_measure(r) + cq_measure(b0);
}
int main(void){ return slice(5); }
