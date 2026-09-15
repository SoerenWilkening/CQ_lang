/* Track S — THE DETERMINING PROBE (A): the per-trip leaked rail is derived from
   a LOOP-INVARIANT register that is STILL LIVE after the loop and is then
   RE-ROTATED (the interference Rule 8 names).  No tainted control flow at all,
   so `collapseFlattenedLoopRails` early-outs and `markIfIterationLocal` is the
   only marker — and it has no `invariantRegisterRoots` escape. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure((y >> k) & 1);
    y = cq_theta(y, 0.9);          /* the diffusion: y is LIVE and interfered */
    return s + cq_measure(y);
}
int main(void) { return slice(); }
