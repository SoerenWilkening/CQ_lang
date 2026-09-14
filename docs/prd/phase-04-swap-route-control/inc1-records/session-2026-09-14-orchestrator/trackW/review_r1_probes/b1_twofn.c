/* B1 — TWO FUNCTIONS, each with its own clause-(c) loop. `f_pass` is w_i (the
   re-ask PASSES); `f_fail` is w_j (the re-ask MUST decline: no marking, derived
   per-trip chain). `declineUnmarkedRolledIterLocal`'s `Diagnosed` set of
   `const Loop*` OUTLIVES the per-function `LoopInfo` that owns those Loop
   objects, so f_fail's Loop* may alias f_pass's freed one and be SKIPPED. */
#include "CQ.h"
__attribute__((noinline)) int f_pass(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        bool t = cq_theta((bool)0, 0.5);
        int r = cq_theta(7, 0.25);
        if (t) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(t);
    }
    return s;
}
__attribute__((noinline)) int f_fail(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(5, 0.5);
        int r = cq_theta(7, 0.25);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(u);
    }
    return s;
}
int main(void) { return f_pass() + f_fail(); }
