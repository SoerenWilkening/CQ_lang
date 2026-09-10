/* p02 — AREA 7 (round-2 §5 "clones"): a bare `_Bool` rail created INSIDE a
   would-be specialized callee, with a 4.4 rail select in it. Round 2 argued the
   clone path cannot see a rail because such a callee declines
   `callee contains a quantum primitive (cq_*)`. Measure it rather than assume. */
#include "CQ.h"
__attribute__((noinline))
static int inner(int s) {
    _Bool b = cq_theta((_Bool)(s & 1), 0.25);
    int a = b ? 2 : 5;
    return cq_measure(a);
}
int main(void) {
    int q = cq_theta(3, 0.5);
    return inner(q);
}
